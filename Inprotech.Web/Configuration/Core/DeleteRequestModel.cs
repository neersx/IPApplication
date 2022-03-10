using System.Collections.Generic;

namespace Inprotech.Web.Configuration.Core
{
    public class DeleteRequestModel
    {
        public DeleteRequestModel()
        {
            Ids = new List<int>();
        }
        public List<int> Ids { get; set; }
    }
}
