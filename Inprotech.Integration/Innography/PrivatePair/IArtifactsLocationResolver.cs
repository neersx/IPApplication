namespace Inprotech.Integration.Innography.PrivatePair
{
    public interface IArtifactsLocationResolver
    {
        string Resolve(Session session, string fileName = "");

        string Resolve(ApplicationDownload application, string fileName = "");

        string ResolveFiles(ApplicationDownload application, string fileName = "");

        string ResolveBiblio(ApplicationDownload application);
    }
}