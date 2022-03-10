using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Picklists;
using System.Collections.Generic;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    public class CountryModel
    {
        public string Key { get { return Code; } }
        public string Code { get; set; }
        public string Value { get; set; }
    }
    
    public class ValidationResult
    {
        public string Result { get; set; }
        public string Message { get; set; }
        public string ValidationMessage { get; set; }
        public string ConfirmationMessage { get; set; }
        public string Title { get; set; }
        public string[] Countries { get; set; }
        public string[] CountryKeys { get; set; }

        public dynamic AsErrorResponse()
        {
            return new
            {
                Errors = new[]
                {
                    new ValidationError(null, Message)
                }
            };
        }
    }

    public class DeleteResponseModel<T> where T : class
    {
        public List<T> InUseIds { get; set; }
        public bool HasError { get; set; }
        public string Message { get; set; }

        public string Result { get; set; }
    }

    public abstract class ValidCombinationSaveModel
    {
        protected ValidCombinationSaveModel()
        {
            SkipDuplicateCheck = false;
        }
        public CountryModel[] Jurisdictions { get; set; }
        public PropertyType PropertyType { get; set; }
        public CaseType CaseType { get; set; }
        public CaseCategory CaseCategory { get; set; }

        public bool SkipDuplicateCheck { get; set; }
    }

    public class ValidCombinationKeys
    {
        public string CaseType { get; set; }
        public string Jurisdiction { get; set; }
        public string PropertyType { get; set; }
        public string CaseCategory { get; set; }

    }
}
