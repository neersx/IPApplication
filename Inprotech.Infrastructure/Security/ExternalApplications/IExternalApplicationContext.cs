namespace Inprotech.Infrastructure.Security.ExternalApplications
{
    public interface IExternalApplicationContext
    {
        string ExternalApplicationName { get; }
        void SetApplicationName(string externalApplicationName);
    }
}
