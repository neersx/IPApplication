using System.Collections.Generic;

namespace Inprotech.Web.Configuration.Core
{
    public class DeleteResponseModel
    {
        public DeleteResponseModel()
        {
            InUseIds = new List<int>();
        }

        public List<int> InUseIds { get; set; }
        public bool HasError { get; set; }
        public string Message { get; set; }
    }
}
