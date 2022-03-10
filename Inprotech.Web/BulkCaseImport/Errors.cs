using System.Collections.Generic;
using Inprotech.Web.BulkCaseImport.Validators;

namespace Inprotech.Web.BulkCaseImport
{
    public static class Errors
    {
        public static dynamic CreateErrorResult(string error, string resultType = "invalid-input")
        {
            return CreateErrorResult(new[] { new ValidationError(error) }, resultType);
        }

        public static dynamic CreateErrorResult(IEnumerable<dynamic> errors, string resultType = "invalid-input")
        {
            return new { Result = resultType, Errors = errors };
        }
    }
}
