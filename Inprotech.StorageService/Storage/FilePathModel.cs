using System.Collections.Generic;
using System.Linq;

namespace Inprotech.StorageService.Storage
{
    public class FilePathModel
    {
        public string PathShortName { get; set; }
        public string Path { get; set; }
        public IEnumerable<FilePathModel> SubFolders { get; set; }

        public FilePathModel()
        {
            SubFolders = Enumerable.Empty<FilePathModel>();
        }
    }
}