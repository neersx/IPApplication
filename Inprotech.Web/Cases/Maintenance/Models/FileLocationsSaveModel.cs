using Inprotech.Web.CaseSupportData;

namespace Inprotech.Web.Cases.Maintenance.Models
{
    public class FileLocationsSaveModel
    {
        public FileLocationsData[] Rows { get; set; }
    }

    public class FileLocationsInputNames
    {
        public const string FileLocation = "fileLocation";
        public const string ActiveFileRequest = "activeFileRequest";
    }
}
