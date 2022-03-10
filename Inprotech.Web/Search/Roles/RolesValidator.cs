using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Search.Roles
{
    public interface IRolesValidator
    {
        IEnumerable<ValidationError> Validate(int roleId, string roleName, Operation operation);
    }

    public class RolesValidator : IRolesValidator
    {
        readonly IDbContext _dbContext;

        public RolesValidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<ValidationError> Validate(int roleId, string roleName, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(roleName))
                yield return validationError;

            foreach (var vr in CheckForErrors(roleId, roleName, operation)) yield return vr;
        }

        IEnumerable<ValidationError> CheckForErrors(int roleId, string roleName, Operation operation)
        {
            var all = _dbContext.Set<Role>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != roleId))
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var others = operation == Operation.Update ? all.Where(_ => _.Id != roleId).ToArray() : all;
            if (others.Any(_ => _.RoleName.IgnoreCaseEquals(roleName)))
            {
                yield return ValidationErrors.NotUnique("rolename");
            }
        }
    }
}