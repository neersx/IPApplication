using System;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class FileLocationModel
    {
        public FileLocationModel(TableCode fileLocation)
        {
            if(fileLocation == null) throw new ArgumentNullException("fileLocation");

            LocationId = fileLocation.Id;
            LocationName = fileLocation.Name;
            LocationCode = fileLocation.UserCode;
        }

        public int? LocationId { get; set; }
        public string LocationName { get; set; }
        public string LocationCode { get; set; }
    }
}