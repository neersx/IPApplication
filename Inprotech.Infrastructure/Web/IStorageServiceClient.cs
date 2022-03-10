using System.Net.Http;
using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Web
{
    public interface IStorageServiceClient
    {
        Task<bool> ValidatePath(string api, HttpRequestMessage request);
        Task<DirectoryValidationResult> ValidateDirectory(string api, HttpRequestMessage request);
        Task RefreshCache<T>(HttpRequestMessage request, T attachmentSettings);
        Task<HttpResponseMessage> GetDirectoryFolders(HttpRequestMessage request);
        Task<HttpResponseMessage> GetDirectoryFiles(string path, HttpRequestMessage request);
        Task<HttpResponseMessage> UploadFile(HttpRequestMessage request);
        Task<HttpResponseMessage> GetFile(int activityKey, int? sequenceKey, string path, HttpRequestMessage request);
    }
    
    public class DirectoryValidationResult
    {
        public bool IsLinkedToStorageLocation { get; set; }
        public bool DirectoryExists { get; set; }
    }
}