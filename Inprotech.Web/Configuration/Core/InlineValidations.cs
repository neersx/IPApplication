using System.Collections.Generic;

namespace Inprotech.Web.Configuration.Core
{
    public class InlineValidationResult
    {
        public string Result { get; set; }

        public List<InlineValidationError> ValidationErrors { get; set; }

        public InlineValidationResult()
        {
        }
        public InlineValidationResult(string result)
        {
            Result = result;
            ValidationErrors = new List<InlineValidationError>();
        }
    }

    public class InlineValidationError
    {
        public InlineValidationError()
        {
            InUseIds = new List<string>();
        }

        public InlineValidationError(string field, string message, dynamic id)
        {
            Field = field;
            Message = message;
            Id = id;
        }

        public List<string> InUseIds { get; set; }

        public string Field { get; set; }

        public string Message { get; set; }

        public dynamic Id { get; set; }
    }
}

