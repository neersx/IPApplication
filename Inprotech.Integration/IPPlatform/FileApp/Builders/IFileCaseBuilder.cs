using System.Threading.Tasks;

namespace Inprotech.Integration.IPPlatform.FileApp.Builders
{
    public interface IFileCaseBuilder
    {
        Task<Models.FileCase> Build(string parentCaseId);
    }
}