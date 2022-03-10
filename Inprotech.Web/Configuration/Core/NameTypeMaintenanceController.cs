using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Extentions;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using CaseName = InprotechKaizen.Model.Cases.CaseName;

namespace Inprotech.Web.Configuration.Core
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.MaintainNameTypes)]
    [RoutePrefix("api/configuration/nametypes")]
    public class NameTypeMaintenanceController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly INameTypeValidator _nameTypeValidator;

        public NameTypeMaintenanceController(IDbContext dbContext, INameTypeValidator nameTypeValidator)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _nameTypeValidator = nameTypeValidator ?? throw new ArgumentNullException(nameof(nameTypeValidator));
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        public dynamic ViewData()
        {
            return null;
        }

        [HttpGet]
        [Route("search")]
        [NoEnrichment]
        public dynamic Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] NameTypeSearchOptions searchOptions)
        {
            IQueryable<NameType> results;
            var nameTypeCode = new List<string>();

            var nameGroupMembers = _dbContext.Set<NameGroupMember>()
                                             .GroupBy(_ => _.NameTypeCode).ToList()
                                             .ToDictionary(g => g.Key, g => g.Select(d => d.NameGroup).ToArray());

            if (searchOptions != null)
            {
                var searchText = searchOptions.Text ?? string.Empty;

                results = _dbContext.Set<NameType>().Where(nt =>
                                                               nt.NameTypeCode.Contains(searchText) || nt.Name.Contains(searchText));
                if (searchOptions.NameTypeGroup != null)
                {
                    foreach (var nameTypeGroup in searchOptions.NameTypeGroup)
                    {
                        var typCode = _dbContext.Set<NameGroupMember>().Where(nt =>
                                                                                  nt.NameGroupId == nameTypeGroup.Key).Select(nt => nt.NameTypeCode).ToList();
                        nameTypeCode.AddRange(typCode);
                    }

                    results = results.Where(nt => nameTypeCode.Any(ntc => ntc.Equals(nt.NameTypeCode)));
                }
            }
            else
            {
                results = _dbContext.Set<NameType>();
            }

            var data = results.ToList()
                              .OrderByProperty("PriorityOrder", "asc")
                              .Select(_ => new
                              {
                                  _.Id,
                                  Code = _.NameTypeCode,
                                  Description = _.Name,
                                  _.PriorityOrder,
                                  NameTypeGroups = nameGroupMembers.ContainsKey(_.NameTypeCode)
                                      ? nameGroupMembers[_.NameTypeCode]
                                          .Select(ng => new NameTypeGroupMember{ Id = ng.Id, Description = ng.Value})
                                      : null
                              });

            return data;
        }

        [HttpGet]
        [Route("{id}")]
        [NoEnrichment]
        public dynamic GetNameType(int id)
        {
            var nameType = _dbContext.Set<NameType>().SingleOrDefault(_ => _.Id == id);

            if (nameType == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var translator = new NameTypeTranslator(_dbContext);
            return translator.SetNameTypeSaveDetailsFromNameType(nameType);
        }

        [HttpPost]
        [Route("")]
        public dynamic Save(NameTypeSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            var validationErrors = _nameTypeValidator.Validate(saveDetails, Operation.Add).ToArray();

            if (!validationErrors.Any())
            {
                var translator = new NameTypeTranslator(_dbContext);
                var entity = translator.AddNameType(saveDetails);

                short priorityOrder = -1;
                if (_dbContext.Set<NameType>().Any())
                    priorityOrder = _dbContext.Set<NameType>().Max(m => m.PriorityOrder);

                entity.PriorityOrder = ++priorityOrder;

                _dbContext.Set<NameType>().Add(entity);

                if (saveDetails.NameTypeGroup != null && saveDetails.NameTypeGroup.Any())
                {
                    foreach (var nameGroupToBeAdded in saveDetails.NameTypeGroup)
                    {
                        var nameGroup = _dbContext.Set<NameGroup>().Single(_ => _.Id.Equals(nameGroupToBeAdded.Key));
                        _dbContext.Set<NameGroupMember>().Add(new NameGroupMember(nameGroup, entity));
                    }
                }

                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    UpdatedId = entity.Id
                };
            }

            return validationErrors.AsErrorResponse();
        }

        [HttpPut]
        [Route("{id}")]
        public dynamic Update(short id, NameTypeSaveDetails saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            var entityToUpdate = _dbContext.Set<NameType>().SingleOrDefault(_ => _.Id == id);

            if (entityToUpdate == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var validationErrors = _nameTypeValidator.Validate(saveDetails, Operation.Update).ToArray();

            if (!validationErrors.Any())
            {
                var translator = new NameTypeTranslator(_dbContext);
                entityToUpdate = translator.SetNameTypeFromDetails(saveDetails, entityToUpdate);

                if (saveDetails.AddNameTypeClassification)
                {
                    var caseNames =
                        _dbContext.Set<CaseName>().Where(cn => cn.NameTypeId == saveDetails.NameTypeCode).ToArray();

                    foreach (var caseName in caseNames.Where(caseName => !_dbContext.Set<NameTypeClassification>()
                                                                                    .Any(ntc => ntc.Name.Id == caseName.Name.Id && ntc.NameType.Id == caseName.NameType.Id)))
                    {
                        _dbContext.Set<NameTypeClassification>()
                                  .Add(new NameTypeClassification(caseName.Name, caseName.NameType) { IsAllowed = 1 });
                    }
                }

                var nameGroupsToBeRemoved = _dbContext.Set<NameGroupMember>().Where(ngm => ngm.NameTypeCode == saveDetails.NameTypeCode).ToArray();

                foreach (var nameGroupToBeRemoved in nameGroupsToBeRemoved)
                {
                    _dbContext.Set<NameGroupMember>().Remove(nameGroupToBeRemoved);
                }

                if (saveDetails.NameTypeGroup != null && saveDetails.NameTypeGroup.Any())
                {
                    foreach (var nameTypeGroup in saveDetails.NameTypeGroup)
                    {
                        var nameGroup = _dbContext.Set<NameGroup>().Single(_ => _.Id.Equals(nameTypeGroup.Key));

                        _dbContext.Set<NameGroupMember>().Add(new NameGroupMember(nameGroup, entityToUpdate));
                    }
                }

                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    UpdatedId = entityToUpdate.Id
                };
            }

            return validationErrors.AsErrorResponse();
        }

        [HttpPost]
        [Route("delete")]
        [NoEnrichment]
        public DeleteResponseModel Delete(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var nameTypes = _dbContext.Set<NameType>().
                                            Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();

                response.InUseIds = new List<int>();

                foreach (var nameType in nameTypes)
                {
                    try
                    {
                        _dbContext.Set<NameType>().Remove(nameType);
                        _dbContext.SaveChanges();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(nameType.Id);
                        }
                        _dbContext.Detach(nameType);
                    }
                }

                txScope.Complete();

                if (response.InUseIds.Any())
                {
                    response.HasError = true;
                    response.Message = ConfigurationResources.InUseErrorMessage;
                    return response;
                }
            }
            return response;
        }

        [HttpPut]
        [Route("updatenametypessequence")]
        public dynamic UpdateNameTypesSequence(PriorityOrderSaveDetails[] saveDetails)
        {
            if (saveDetails == null) throw new ArgumentNullException(nameof(saveDetails));

            var filtered = _dbContext.Set<NameType>();

            foreach (var record in filtered)
            {
                var nameType = saveDetails.SingleOrDefault(_ => _.Id == record.Id);
                if (nameType != null) record.PriorityOrder = nameType.PriorityOrder;
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = "success"
            };
        }

    }

    public class PriorityOrderSaveDetails
    {
        public int Id { get; set; }
        public short PriorityOrder { get; set; }
    }

    public class NameTypeGroupMember
    {
        public int Id { get; set; }

        public string Description { get; set; }
    }

    public class NameTypeSearchOptions : SearchOptions
    {
        public ICollection<NameTypeGroup> NameTypeGroup { get; set; }
    }

}
