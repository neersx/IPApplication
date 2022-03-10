using Inprotech.Integration.Artifacts;

namespace Inprotech.Integration.CaseSource
{
    public interface IProvideCaseResolvers
    {
        IResolveCasesForDownload Get(DataDownload session);
    }
}
