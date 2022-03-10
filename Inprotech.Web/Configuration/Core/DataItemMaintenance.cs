using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Web.Http;
using AutoMapper;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Extentions;
using Inprotech.Web.InproDoc.Config;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using Inprotech.Web.SchemaMapping;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using DocItem = InprotechKaizen.Model.Documents.DocItem;

namespace Inprotech.Web.Configuration.Core
{
    public interface IDataItemMaintenance
    {
        IEnumerable<DataItemGroup> DataItemGroups(int dataItemId);
        EntryPoint EntryPoint(DocItem dataItem);
        dynamic DataItem(int dataItemId, bool forPickList = false);
        DeleteResponseModel Delete(DeleteRequestModel deleteRequestModel);
        dynamic Save(DataItemPayload payloadInfo, dynamic keyInfo);
        dynamic Update(int id, DataItemPayload payloadInfo, dynamic keyInfo);
        IEnumerable<Infrastructure.Validations.ValidationError> ValidateSql(DocItem item, DataItemPayload payloadInfo);
    }

    public class DataItemMaintenance : IDataItemMaintenance
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IPassThruManager _passThruManager;
        readonly IDocItemReader _docItemReader;
        readonly ISqlHelper _sqlHelper;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _now;
        IMapper _mapper;

        public DataItemMaintenance(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver,
                                     IPassThruManager passThruManager, IDocItemReader docItemReader, ISqlHelper sqlHelper,
                                     ILastInternalCodeGenerator lastInternalCodeGenerator, ISecurityContext securityContext, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _passThruManager = passThruManager;
            _docItemReader = docItemReader;
            _sqlHelper = sqlHelper;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
            _securityContext = securityContext;
            _now = now;

            ConfigureMappers();
        }

        public IEnumerable<DataItemGroup> DataItemGroups(int dataItemId)
        {
            var groups = ItemGroups(dataItemId).ToArray();
            return groups.Any() ? groups.Select(_ => new DataItemGroup(_.Code, _.Name)) : Enumerable.Empty<DataItemGroup>();
        }

        IEnumerable<Group> ItemGroups(int dataItemId)
        {
            var groupItems = _dbContext.Set<ItemGroup>().Where(_ => _.ItemId == dataItemId).ToArray();

            if (!groupItems.Any()) return Enumerable.Empty<Group>();

            return Groups().Where(_ => groupItems.Select(gi => gi.Code).Contains(_.Code));
        }

        IEnumerable<Group> Groups()
        {
            var culture = _preferredCultureResolver.Resolve();
            var translated = _dbContext.Set<Group>().Select(_ => new
            {
                _.Code,
                Description = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture)
            });

            return translated.AsEnumerable().Select(_ => new Group(_.Code, _.Description));
        }

        public EntryPoint EntryPoint(DocItem dataItem)
        {
            return new EntryPoint
            {
                Name = dataItem.EntryPointUsage,
                Description = _passThruManager.GetEntryPoints()
                                                .FirstOrDefault(_ => _.Name == dataItem.EntryPointUsage.ToString())?.Description
            };
        }

        public dynamic DataItem(int dataItemId, bool forPickList = false)
        {
            var dataItem = _dbContext.Set<DocItem>()
                                     .Single(_ => _.Id == dataItemId);

            if (dataItem == null)
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.DataItemDoesNotExist.ToString());

            var item = new DataItemPayload().ToSaveDetails(dataItem, this);

            if (forPickList)
            {
                var mapped = _mapper.Map<DataItemPayload, DataItem>(item.PayloadInfo);
                mapped.Key = item.KeyInfo.Id;
                mapped.Code = item.KeyInfo.Name;
                mapped.Value = item.KeyInfo.Description;
                return mapped;
            }
            else
            {
                var mapped = _mapper.Map<DataItemPayload, DataItemEntity>(item.PayloadInfo);
                mapped.Id = item.KeyInfo.Id;
                mapped.Name = item.KeyInfo.Name;
                mapped.Description = item.KeyInfo.Description;
                return mapped;
            }
        }

        public DeleteResponseModel Delete(DeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null || !deleteRequestModel.Ids.Any()) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new DeleteResponseModel();

            using (var txScope = _dbContext.BeginTransaction())
            {
                var dataItems = _dbContext.Set<DocItem>().Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();

                foreach (var dataItem in dataItems)
                {
                    try
                    {
                        var itemGroups = _dbContext.Set<ItemGroup>().Where(_ => _.ItemId == dataItem.Id).ToArray();

                        foreach (var itemGroup in itemGroups)
                        {
                            _dbContext.Set<ItemGroup>().Remove(itemGroup);
                        }

                        _dbContext.SaveChanges();

                        var itemNote = _dbContext.Set<ItemNote>().FirstOrDefault(_ => _.ItemId == dataItem.Id);

                        if (itemNote != null) _dbContext.Set<ItemNote>().Remove(itemNote);

                        _dbContext.Set<DocItem>().Remove(dataItem);

                        _dbContext.SaveChanges();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(dataItem.Id);
                        }
                        _dbContext.Detach(dataItem);
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

        public dynamic Save(DataItemPayload payloadInfo, dynamic keyInfo)
        {
            var validationErrors = (IEnumerable<Infrastructure.Validations.ValidationError>)Validate(keyInfo, Operation.Add);
            var enumerable = validationErrors as Infrastructure.Validations.ValidationError[] ?? validationErrors.ToArray();
            if (enumerable.Any()) return enumerable.AsErrorResponse();

            var lastInternalCode = _lastInternalCodeGenerator.GenerateLastInternalCode("ITEM");

            var entity = new DocItem();

            entity = MapEntity(lastInternalCode, payloadInfo, keyInfo, entity);

            entity.CreatedBy = _securityContext.User.UserName;
            entity.DateCreated = entity.DateUpdated = _now();

            validationErrors = ValidateSql(entity, payloadInfo).ToArray();
            var errors = validationErrors as Infrastructure.Validations.ValidationError[];
            if (errors.Any()) return errors.AsErrorResponse();

            PopulateSqlDescribeAndSqlInto(entity, payloadInfo.ReturnsImage);

            _dbContext.Set<DocItem>().Add(entity);

            if (payloadInfo.ItemGroups != null && payloadInfo.ItemGroups.Any())
            {
                foreach (var itemGroupToBeAdded in payloadInfo.ItemGroups)
                {
                    var itemGroup = new ItemGroup
                    {
                        Code = itemGroupToBeAdded.Code,
                        ItemId = lastInternalCode
                    };

                    _dbContext.Set<ItemGroup>().Add(itemGroup);
                }
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = "success",
                UpdatedId = entity.Id,
                Key = entity.Id
            };
        }

        public dynamic Update(int id, DataItemPayload payloadInfo, dynamic keyInfo)
        {
            var entity = _dbContext.Set<DocItem>().SingleOrDefault(_ => _.Id == id);

            if (entity == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var validationErrors = (IEnumerable<Infrastructure.Validations.ValidationError>)Validate(keyInfo, Operation.Update);

            var enumerable = validationErrors as Infrastructure.Validations.ValidationError[] ?? validationErrors.ToArray();
            if (!enumerable.Any())
            {
                var itemNote = _dbContext.Set<ItemNote>().SingleOrDefault(nt => nt.ItemId == entity.Id);
                if (itemNote != null)
                {
                    _dbContext.Set<ItemNote>().Remove(itemNote);
                    _dbContext.SaveChanges();
                }

                entity = MapEntity(id, payloadInfo, keyInfo, entity);
                entity.DateUpdated = _now();

                validationErrors = ValidateSql(entity, payloadInfo).ToArray();
                var errors = validationErrors as Infrastructure.Validations.ValidationError[];
                if (errors.Any()) return errors.AsErrorResponse();

                PopulateSqlDescribeAndSqlInto(entity, payloadInfo.ReturnsImage);

                var itemGroupsToBeRemoved = _dbContext.Set<ItemGroup>().Where(_ => _.ItemId == id);

                _dbContext.RemoveRange(itemGroupsToBeRemoved);

                if (payloadInfo.ItemGroups != null && payloadInfo.ItemGroups.Any())
                {
                    foreach (var itemGroupsToBeAdded in payloadInfo.ItemGroups)
                    {
                        var itemGroup = new ItemGroup
                        {
                            Code = itemGroupsToBeAdded.Code,
                            ItemId = entity.Id
                        };

                        _dbContext.Set<ItemGroup>().Add(itemGroup);
                    }
                }

                _dbContext.SaveChanges();

                return new
                {
                    Result = "success",
                    Key = entity.Id,
                    UpdatedId = entity.Id

                };
            }

            return enumerable.AsErrorResponse();
        }

        DocItem MapEntity(int id, DataItemPayload payloadInfo, dynamic keyInfo, DocItem entity)
        {
            if (payloadInfo is DataItem)
            {
                var mapped = _mapper.Map<DataItemPayload, DataItem>(payloadInfo);
                mapped.Key = id;
                mapped.Code = keyInfo.Name;
                mapped.Value = keyInfo.Description;
                entity = entity.FromSaveDetails(mapped);
            }
            else
            {
                var mapped = _mapper.Map<DataItemPayload, DataItemEntity>(payloadInfo);
                mapped.Id = id;
                mapped.Name = keyInfo.Name;
                mapped.Description = keyInfo.Description;
                entity = entity.FromSaveDetails(mapped);
            }
            return entity;
        }

        public IEnumerable<Infrastructure.Validations.ValidationError> Validate(dynamic keyInfo, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(keyInfo))
                yield return validationError;

            foreach (var vr in CheckForErrors(keyInfo, operation)) yield return vr;
        }

        IEnumerable<Infrastructure.Validations.ValidationError> CheckForErrors(dynamic modelInfo, Operation operation)
        {
            var id = (int)modelInfo.Id;
            var name = (string)modelInfo.Name;

            var all = _dbContext.Set<DocItem>().ToArray();

            if (operation == Operation.Update &&
                all.All(_ => _.Id != id))
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            var others = operation == Operation.Update ? all.Where(_ => _.Id != id).ToArray() : all;
            if (others.Any(_ => _.Name.IgnoreCaseEquals(name)))
            {
                yield return ValidationErrors.NotUnique(string.Format(Resources.ErrorDuplicateDataItemName, name), "code");
            }
        }

        public void PopulateSqlDescribeAndSqlInto(DocItem entity, bool returnsImage)
        {
            var returnColumnInformation = _docItemReader.ReturnColumnInformation(entity, returnsImage);

            entity.SqlDescribe = returnColumnInformation.SqlDescribe;
            entity.SqlInto = returnColumnInformation.SqlInto;
        }

        public IEnumerable<Infrastructure.Validations.ValidationError> ValidateSql(DocItem item, DataItemPayload payloadInfo)
        {
            var fieldName = payloadInfo.IsSqlStatement ? "statement" : "procedurename";

            var message = string.Empty;
            var invalidSqlmessageId = "field.errors.invalidsql";
            ReturnColumnSchema[] columSchemaCollection = null;

            try
            {
                columSchemaCollection = _docItemReader.ReturnColumnSchema(item).ToArray();
            }
            catch (Exception ex)
            {
                message = ex.Message;
            }

            if (!string.IsNullOrEmpty(message))
            {
                yield return ValidationErrors.Invalid(invalidSqlmessageId, fieldName, payloadInfo.IsSqlStatement ? Resources.NoColumnSql : Resources.NoColumnStoredProcedure);
            }
            else
            {
                if (payloadInfo.ItemGroups != null && payloadInfo.ItemGroups.Any(_ => _.Value.Equals(KnownGroupCodes.CaseValidation, StringComparison.InvariantCultureIgnoreCase)))
                {
                    if (_docItemReader.InvalidFormatCaseIdForCaseValidation(item))
                    {
                        yield return ValidationErrors.Invalid(invalidSqlmessageId, fieldName, Resources.InvalidCaseIdForCaseValidationSql);
                    }
                }

                if (payloadInfo.ReturnsImage && columSchemaCollection != null)
                {
                    var possibleImageColumns = columSchemaCollection.Count(_ => _.ColumnSize > 255 && KnownDbDataTypes.StringDataTypes.Contains(_.DataTypeName));
                    if (possibleImageColumns == 0)
                        yield return ValidationErrors.Invalid(invalidSqlmessageId, fieldName, Resources.NoImageColumn);
                    if (possibleImageColumns > 1)
                        yield return ValidationErrors.Invalid(invalidSqlmessageId, fieldName, Resources.MultipleImageColumn);
                }
                if ((columSchemaCollection != null && columSchemaCollection.ToArray().Length == 0) || (!payloadInfo.IsSqlStatement && !_sqlHelper.DeriveParameters(payloadInfo.Sql.StoredProcedure).Any()))
                {
                    yield return ValidationErrors.Invalid(invalidSqlmessageId, fieldName, payloadInfo.IsSqlStatement ? Resources.NoColumnSql : Resources.NoColumnStoredProcedure);
                }
            }
        }

        void ConfigureMappers()
        {
            var config = new MapperConfiguration(cfg =>
            {
                cfg.CreateMap<DataItemPayload, DataItem>();
                cfg.CreateMap<DataItemPayload, DataItemEntity>();
                cfg.CreateMissingTypeMaps = true;
            });

            _mapper = config.CreateMapper();
        }
    }
}
