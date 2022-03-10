using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Core
{
    public interface INameTypeValidator
    {
        IEnumerable<Infrastructure.Validations.ValidationError> Validate(NameTypeSaveDetails nameType, Operation operation);
    }

    public class NameTypeValidator : INameTypeValidator
    {
        readonly IDbContext _dbContext;

        public NameTypeValidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<Infrastructure.Validations.ValidationError> Validate(NameTypeSaveDetails nameType, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(nameType))
                yield return validationError;

            foreach (var vr in CheckForErrors(nameType.Id, nameType.NameTypeCode, operation)) yield return vr;
        }

        IEnumerable<Infrastructure.Validations.ValidationError> CheckForErrors(int id, string code, Operation operation)
        {
            var all = _dbContext.Set<NameType>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != id))
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var others = operation == Operation.Update ? all.Where(_ => _.Id != id).ToArray() : all;
            if (others.Any(_ => _.NameTypeCode.IgnoreCaseEquals(code)))
            {
                yield return ValidationErrors.NotUnique(string.Format(Resources.ErrorDuplicateNameTypeCode, code), "nameTypeCode");
            }
        }
    }
}
