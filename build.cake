//////////////////////////////////////////////////////////////////////
// ADDINS
//////////////////////////////////////////////////////////////////////

#addin "nuget:?package=MagicChunks&version=2.0.0.119"
#addin "nuget:?package=Cake.Tfx&version=0.4.2"
#addin "nuget:?package=Cake.Npm&version=0.10.0"
#addin "nuget:?package=Cake.AppVeyor&version=1.1.0.9"
#addin "nuget:?package=Cake.Wyam&version=1.7.4"
#addin "nuget:?package=Cake.Git&version=0.19.0"
#addin "nuget:?package=Cake.Kudu&version=0.8.0"
#addin "nuget:?package=Cake.Gitter&version=0.10.0"
#addin "nuget:?package=Cake.Twitter&version=0.9.0"

//////////////////////////////////////////////////////////////////////
// TOOLS
//////////////////////////////////////////////////////////////////////

#tool "nuget:?package=gitreleasemanager&version=0.7.1"
#tool "nuget:?package=GitVersion.CommandLine&version=3.6.4"
#tool "nuget:?package=Wyam&version=1.7.4"
#tool "nuget:?package=KuduSync.NET&version=1.4.0"

// Load other scripts.
#load "./build/parameters.cake"
#load "./build/wyam.cake"
#load "./build/gitter.cake"
#load "./build/twitter.cake"

//////////////////////////////////////////////////////////////////////
// PARAMETERS
//////////////////////////////////////////////////////////////////////

BuildParameters parameters = BuildParameters.GetParameters(Context, BuildSystem);
bool publishingError = false;

///////////////////////////////////////////////////////////////////////////////
// SETUP / TEARDOWN
///////////////////////////////////////////////////////////////////////////////

Setup(context =>
{
    parameters.SetBuildVersion(
        BuildVersion.CalculatingSemanticVersion(
            context: Context,
            parameters: parameters
        )
    );

    // Increase verbosity?
    if(parameters.IsMasterBranch && (context.Log.Verbosity != Verbosity.Diagnostic)) {
        Information("Increasing verbosity to diagnostic.");
        context.Log.Verbosity = Verbosity.Diagnostic;
    }

    Information("Building version {0} of chocolatey-azuredevops ({1}, {2}) using version {3} of Cake. (IsTagged: {4})",
        parameters.Version.SemVersion,
        parameters.Configuration,
        parameters.Target,
        parameters.Version.CakeVersion,
        parameters.IsTagged);
});

Teardown(context =>
{
    Information("Starting Teardown...");

    if(context.Successful)
    {
        if(!parameters.IsLocalBuild && !parameters.IsPullRequest && parameters.IsMasterRepo && (parameters.IsMasterBranch || ((parameters.IsReleaseBranch || parameters.IsHotFixBranch))) && parameters.IsTagged)
        {
            if(parameters.CanPostToTwitter)
            {
                SendMessageToTwitter();
            }

            if(parameters.CanPostToGitter)
            {
                SendMessageToGitterRoom();
            }
        }
    }

    Information("Finished running tasks.");
});

//////////////////////////////////////////////////////////////////////
// TASKS
//////////////////////////////////////////////////////////////////////

Task("Clean")
    .Does(() =>
{
    CleanDirectories(new[] { "./build-results" });
});

Task("Npm-Install")
    .Does(() =>
{
    var settings = new NpmInstallSettings();
    settings.LogLevel = NpmLogLevel.Silent;
    NpmInstall(settings);
});

Task("Install-Tfx-Cli")
    .Does(() =>
{
    var settings = new NpmInstallSettings();
    settings.Global = true;
    settings.AddPackage("tfx-cli", "0.6.3");
    settings.LogLevel = NpmLogLevel.Silent;
    NpmInstall(settings);
});

Task("Create-Release-Notes")
    .Does(() =>
{
    GitReleaseManagerCreate(parameters.GitHub.UserName, parameters.GitHub.Password, "gep13", "chocolatey-azuredevops", new GitReleaseManagerCreateSettings {
        Milestone         = parameters.Version.Milestone,
        Name              = parameters.Version.Milestone,
        Prerelease        = true,
        TargetCommitish   = "master"
    });
});

Task("Update-Task-Json-Versions")
    .DoesForEach(new [] {"Tasks/chocolatey/task.json", "Tasks/installer/task.json"}, taskJson => 
{
    Information("Updating {0} version -> {1}", taskJson, parameters.Version.SemVersion);

    TransformConfig(taskJson, taskJson, new TransformationCollection {
        { "version/Major", parameters.Version.Major }
    });

    TransformConfig(taskJson, taskJson, new TransformationCollection {
        { "version/Minor", parameters.Version.Minor }
    });

    TransformConfig(taskJson, taskJson, new TransformationCollection {
        { "version/Patch", parameters.Version.Patch }
    });
});

Task("Update-Manifest-Json-Version")
    .Does(() =>
{
    var projectToPackagePackageJson = "vss-extension.json";
    Information("Updating {0} version -> {1}", projectToPackagePackageJson, parameters.Version.SemVersion);

    TransformConfig(projectToPackagePackageJson, projectToPackagePackageJson, new TransformationCollection {
        { "version", parameters.Version.SemVersion }
    });
});

Task("Package-Extension")
    .IsDependentOn("Update-Manifest-Json-Version")
    .IsDependentOn("Update-Task-Json-Versions")
    .IsDependentOn("Npm-Install")
    .IsDependentOn("Install-Tfx-Cli")
    .IsDependentOn("Clean")
    .Does(() =>
{
    var buildResultDir = Directory("./build-results");

    TfxExtensionCreate(new TfxExtensionCreateSettings()
    {
        ManifestGlobs = new List<string>(){ "./vss-extension.json" },
        OutputPath = buildResultDir
    });
});

Task("Upload-AppVeyor-Artifacts")
    .IsDependentOn("Package-Extension")
    .WithCriteria(() => parameters.IsRunningOnAppVeyor)
.Does(() =>
{
    var buildResultDir = Directory("./build-results");
    var packageFile = File("gep13.chocolatey-azuredevops-" + parameters.Version.SemVersion + ".vsix");
    AppVeyor.UploadArtifact(buildResultDir + packageFile);
});

Task("Publish-GitHub-Release")
    .WithCriteria(() => parameters.ShouldPublish)
    .Does(() =>
{
    var buildResultDir = Directory("./build-results");
    var packageFile = File("gep13.chocolatey-azuredevops-" + parameters.Version.SemVersion + ".vsix");

    GitReleaseManagerAddAssets(parameters.GitHub.UserName, parameters.GitHub.Password, "gep13", "chocolatey-azuredevops", parameters.Version.Milestone, buildResultDir + packageFile);
    GitReleaseManagerClose(parameters.GitHub.UserName, parameters.GitHub.Password, "gep13", "chocolatey-azuredevops", parameters.Version.Milestone);
})
.OnError(exception =>
{
    Information("Publish-GitHub-Release Task failed, but continuing with next Task...");
    publishingError = true;
});

Task("Publish-Extension")
    .IsDependentOn("Package-Extension")
    .WithCriteria(() => parameters.ShouldPublish)
    .Does(() =>
{
    var buildResultDir = Directory("./build-results");
    var packageFile = File("gep13.chocolatey-azuredevops-" + parameters.Version.SemVersion + ".vsix");

    TfxExtensionPublish(buildResultDir + packageFile, new TfxExtensionPublishSettings()
    {
        AuthType = TfxAuthType.Pat,
        Token = parameters.Marketplace.Token
    });
})
.OnError(exception =>
{
    Information("Publish-Extension Task failed, but continuing with next Task...");
    publishingError = true;
});

//////////////////////////////////////////////////////////////////////
// TASK TARGETS
//////////////////////////////////////////////////////////////////////

Task("Default")
    .IsDependentOn("Package-Extension");

Task("Appveyor")
    .IsDependentOn("Upload-AppVeyor-Artifacts")
    .IsDependentOn("Publish-Documentation")
    .IsDependentOn("Publish-Extension")
    .IsDependentOn("Publish-GitHub-Release")
    .Finally(() =>
{
    if(publishingError)
    {
        throw new Exception("An error occurred during the publishing of cake-vscode.  All publishing tasks have been attempted.");
    }
});

Task("ReleaseNotes")
  .IsDependentOn("Create-Release-Notes");

//////////////////////////////////////////////////////////////////////
// EXECUTION
//////////////////////////////////////////////////////////////////////

RunTarget(parameters.Target);
