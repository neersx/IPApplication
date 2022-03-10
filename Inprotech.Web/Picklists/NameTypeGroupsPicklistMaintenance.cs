using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;
using EntityModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Web.Picklists
{
    public interface INameTypeGroupsPicklistMaintenance
    {
        dynamic Save(NameTypeGroup nameTypeGroup, Operation operation);
        dynamic Delete(int id);

    }
    public class NameTypeGroupsPicklistMaintenance : INameTypeGroupsPicklistMaintenance
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public NameTypeGroupsPicklistMaintenance(IDbContext dbContext, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        public dynamic Save(NameTypeGroup nameTypeGroup, Operation operation)
        {
            if (nameTypeGroup == null) throw new ArgumentNullException(nameof(nameTypeGroup));

            var validationErrors = Validate(nameTypeGroup, operation).ToArray();
            if (!validationErrors.Any())
            {
                using (var tcs = _dbContext.BeginTransaction())
                {
                    if (operation == Operation.Add)
                    {
                        var newNameGroupId = (short)_lastInternalCodeGenerator.GenerateLastInternalCode("NAMEGROUPS");

                        var nameGroup = _dbContext.Set<EntityModel.NameGroup>().Add(new EntityModel.NameGroup(newNameGroupId, nameTypeGroup.Value));

                        if (nameTypeGroup.NameType != null && nameTypeGroup.NameType.Any())
                        {
                            foreach (var nameTypeToBeAdded in nameTypeGroup.NameType)
                            {
                                var nameType = _dbContext.Set<EntityModel.NameType>().Single(_ => _.NameTypeCode.Equals(nameTypeToBeAdded.Code));
                                _dbContext.Set<EntityModel.NameGroupMember>().Add(new EntityModel.NameGroupMember(nameGroup, nameType));
                            }
                        }

                        _dbContext.SaveChanges();
                    }
                    else
                    {
                        var nameGroup = _dbContext.Set<EntityModel.NameGroup>().Single(_ => _.Id == nameTypeGroup.Key);

                        nameGroup.Value = nameTypeGroup.Value;

                        var nameGroupsToBeRemoved = _dbContext.Set<EntityModel.NameGroupMember>().Where(_ => _.NameGroupId == nameTypeGroup.Key).ToArray();

                        foreach (var nameGroupToBeRemoved in nameGroupsToBeRemoved)
                        {
                            _dbContext.Set<EntityModel.NameGroupMember>().Remove(nameGroupToBeRemoved);
                        }

                        if (nameTypeGroup.NameType != null && nameTypeGroup.NameType.Any())
                        {
                            foreach (var nameTypeToBeAdded in nameTypeGroup.NameType)
                            {
                                var nameType = _dbContext.Set<EntityModel.NameType>().Single(_ => _.NameTypeCode.Equals(nameTypeToBeAdded.Code));
                                _dbContext.Set<EntityModel.NameGroupMember>().Add(new EntityModel.NameGroupMember(nameGroup, nameType));
                            }
                        }
                    }

                    _dbContext.SaveChanges();
                    tcs.Complete();

                    return new
                    {
                        Result = "success",
                        nameTypeGroup.Value
                    };
                }
            }

            return validationErrors.AsErrorResponse();
        }

        public dynamic Delete(int id)
        {
            try
            {
                if (_dbContext.Set<EntityModel.NameGroupMember>().Any(ngm => ngm.NameGroupId == id))
                    return KnownSqlErrors.CannotDelete.AsHandled();

                var entry = _dbContext.Set<EntityModel.NameGroup>().SingleOrDefault(_ => _.Id == id);

                if (entry == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.NameTypeGroupDoesNotExist.ToString());

                using (var tcs = _dbContext.BeginTransaction())
                {
                    var model = _dbContext
                        .Set<EntityModel.NameGroup>()
                        .Single(_ => _.Id == id);
                    if (model == null) HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.NameTypeGroupDoesNotExist.ToString());

                    var groupMembersToBeDeleted = _dbContext.Set<EntityModel.NameGroupMember>().Where(_ => _.NameGroupId == id).ToList();

                    foreach (var groupMemberToBeDeleted in groupMembersToBeDeleted)
                    {
                        _dbContext.Set<EntityModel.NameGroupMember>().Remove(groupMemberToBeDeleted);
                    }

                    _dbContext.Set<EntityModel.NameGroup>().Remove(model);

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

        IEnumerable<ValidationError> Validate(NameTypeGroup nameTypeGroup, Operation operation)
        {
            var all = _dbContext.Set<EntityModel.NameGroup>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != nameTypeGroup.Key))
            {
                throw new ArgumentException("Unable to retrieve subtype for update.");
            }

            foreach (var validationError in CommonValidations.Validate(nameTypeGroup))
                yield return validationError;

            var others = operation == Operation.Update ? all.Where(_ => _.Id != nameTypeGroup.Key).ToArray() : all;

            if (others.Any(_ => _.Value.IgnoreCaseEquals(nameTypeGroup.Value)))
            {
                yield return ValidationErrors.NotUnique("value");
            }
        }
    }
}
