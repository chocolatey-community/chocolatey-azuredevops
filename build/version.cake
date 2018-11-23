public class BuildVersion
{
    public string Version { get; private set; }
    public string SemVersion { get; private set; }
    public string Milestone { get; private set; }
    public string CakeVersion { get; private set; }
    public string Major { get; private set; }
    public string Minor { get; private set; }
    public string Patch { get; private set; }

    public static BuildVersion CalculatingSemanticVersion(
        ICakeContext context,
        BuildParameters parameters
        )
    {
        if (context == null)
        {
            throw new ArgumentNullException("context");
        }

        string version = null;
        string semVersion = null;
        string milestone = null;
        string major = null;
        string minor = null;
        string patch = null;

        if (!parameters.SkipGitVersion)
        {
            context.Information("Calculating Semantic Version");
            if (!parameters.IsLocalBuild || parameters.IsPublishBuild || parameters.IsReleaseBuild)
            {
                context.GitVersion(new GitVersionSettings{
                    OutputType = GitVersionOutput.BuildServer
                });

                version = context.EnvironmentVariable("GitVersion_MajorMinorPatch");
                semVersion = context.EnvironmentVariable("GitVersion_LegacySemVerPadded");
                milestone = string.Concat("v", version);
                major = context.EnvironmentVariable("GitVersion_Major");
                minor = context.EnvironmentVariable("GitVersion_Minor");
                patch = context.EnvironmentVariable("GitVersion_Patch");
            }

            GitVersion assertedVersions = context.GitVersion(new GitVersionSettings
            {
                OutputType = GitVersionOutput.Json,
            });

            version = assertedVersions.MajorMinorPatch;
            semVersion = assertedVersions.LegacySemVerPadded;
            milestone = version;
            major = assertedVersions.Major.ToString();
            minor = assertedVersions.Minor.ToString();
            patch = assertedVersions.Patch.ToString();

            context.Information("Calculated Semantic Version: {0}", semVersion);
        }

        var cakeVersion = typeof(ICakeContext).Assembly.GetName().Version.ToString();

        return new BuildVersion
        {
            Version = version,
            SemVersion = semVersion,
            Milestone = milestone,
            CakeVersion = cakeVersion,
            Major = major,
            Minor = minor,
            Patch = patch
        };
    }
}
