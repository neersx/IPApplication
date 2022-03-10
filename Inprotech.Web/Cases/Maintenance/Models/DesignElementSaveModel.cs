using Inprotech.Web.CaseSupportData;

namespace Inprotech.Web.Cases.Maintenance.Models
{
    public class DesignElementSaveModel
    {
        public DesignElementData[] Rows { get; set; }
    }

    public class DesignElementsInputNames
    {
        public const string FirmElementId = "firmElementCaseRef";
        public const string ImageId = "images";
    }
}
