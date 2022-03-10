using System.Collections.Generic;
using System.Linq;

namespace InprotechKaizen.Model.Components.Core
{
    public class ValidationError
    {
        public string ErrorCode { get; set; }

        public string ErrorDescription { get; set; }

        public string WarningCode { get; set; }

        public string WarningDescription { get; set; }

    }

    public class ValidationErrorCollection
    {
        public bool HasError => ValidationErrorList.Any(_ => _.ErrorCode != null);
        
        public string FirstErrorDescription => ValidationErrorList.FirstOrDefault(_ => _.ErrorCode != null)?.ErrorDescription;

        public IEnumerable<ValidationError> ValidationErrorList { get; set; } = new List<ValidationError>();
    }

}