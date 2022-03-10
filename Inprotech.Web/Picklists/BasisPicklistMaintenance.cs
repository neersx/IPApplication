using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using EntityModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Web.Picklists
{
    public interface IBasisPicklistMaintenance
    {
        dynamic Save(Basis basis, Operation operation);
        dynamic Delete(int basisId);
        Basis Get(int basisId);
    }

    public class BasisPicklistMaintenance : IBasisPicklistMaintenance
    {
        readonly IDbContext _dbContext;

        public BasisPicklistMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException("dbContext");
        }

        public dynamic Save(Basis basis, Operation operation)
        {
            if (basis == null) throw new ArgumentNullException("basis");

            var validationErrors = Validate(basis, operation).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = operation == Operation.Update
                        ? _dbContext.Set<EntityModel.ApplicationBasis>()
                                    .Single(_ => _.Code == basis.Code)
                        : _dbContext.Set<EntityModel.ApplicationBasis>()
                                    .Add(new EntityModel.ApplicationBasis(basis.Code, basis.Value));

                    model.Name = basis.Value;
                    model.Convention = basis.Convention ? 1m : 0m;
                    _dbContext.SaveChanges();
                    tcs.Complete();

                    return new
                               {
                                   Result = "success",
                                   Key = model.Id
                               };
                }
            }

            return validationErrors.AsErrorResponse();
        }

        public dynamic Delete(int basisId)
        {
            try
            {
                var basis = _dbContext.Set<EntityModel.ApplicationBasis>().Single(_ => _.Id == basisId);

                if(_dbContext.Set<ValidBasis>().Any(vb => vb.BasisId == basis.Code))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext
                        .Set<EntityModel.ApplicationBasis>()
                        .Single(_ => _.Id == basisId);

                    _dbContext.Set<EntityModel.ApplicationBasis>().Remove(model);

                    _dbContext.SaveChanges();
                    tcs.Complete();
                }

                return new
                {
                    Result = "success"
                };
            }
            catch (Exception ex)
            {
                if (!ex.IsForeignKeyConstraintViolation())
                    throw;

                return KnownSqlErrors.CannotDelete.AsHandled();
            }
        }

        IEnumerable<ValidationError> Validate(Basis basis, Operation operation)
        {
            var all = _dbContext.Set<EntityModel.ApplicationBasis>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Code != basis.Code))
            {
                throw new ArgumentException("Unable to retrieve application basis for update.");
            }

            foreach (var validationError in CommonValidations.Validate(basis))
            {
                yield return validationError;
            }

            var others = operation == Operation.Update ? all.Where(_ => _.Code != basis.Code).ToArray() : all;
            if (others.Any(_ => _.Code.IgnoreCaseEquals(basis.Code)))
            {
                yield return ValidationErrors.NotUnique("code");
            }
            if (others.Any(_ => _.Name.IgnoreCaseEquals(basis.Value)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }

        public Basis Get(int basisId)
        {
            var appBasis = _dbContext.Set<EntityModel.ApplicationBasis>().Single(_ => _.Id == basisId);
            return new Basis(appBasis.Id, appBasis.Code, appBasis.Name, appBasis.Convention);
        }
    }
}