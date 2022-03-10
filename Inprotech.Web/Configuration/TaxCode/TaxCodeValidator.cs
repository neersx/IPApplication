using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.TaxCode
{
    public interface ITaxCodesValidator
    {
        IEnumerable<ValidationError> Validate(string taxCode, Operation operation);
    }

    public class TaxCodesValidator : ITaxCodesValidator
    {
        readonly IDbContext _dbContext;

        public TaxCodesValidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<ValidationError> Validate(string taxCode, Operation operation)
        {
            return CheckForErrors(taxCode, operation);
        }

        IEnumerable<ValidationError> CheckForErrors(string taxCode, Operation operation)
        {
            var all = _dbContext.Set<TaxRate>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Code != taxCode))
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var others = operation == Operation.Update ? all.Where(_ => _.Code != taxCode).ToArray() : all;
            if (others.Any(_ => _.Code.Contains(taxCode)))
            {
                yield return ValidationErrors.NotUnique("taxCode");
            }
        }
    }
}