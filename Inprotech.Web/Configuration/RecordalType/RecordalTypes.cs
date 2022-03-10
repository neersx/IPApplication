using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Extentions;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Persistence;
using Action = Inprotech.Web.Picklists.Action;

namespace Inprotech.Web.Configuration.RecordalType
{
    public interface IRecordalTypes
    {
        Task<IEnumerable<RecordalTypeItems>> GetRecordalTypes();
        Task<RecordalTypeModel> GetRecordalTypeForm(int id);
        Task<dynamic> SubmitRecordalTypeForm(RecordalTypeRequest model);
        Task<RecordalElementsModel> GetRecordalElementForm(int id);
        Task<dynamic> GetAllElements();
        Task<dynamic> Delete(int id);
    }

    public class RecordalTypes : IRecordalTypes
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public RecordalTypes(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public async Task<IEnumerable<RecordalTypeItems>> GetRecordalTypes()
        {
            var culture = _preferredCultureResolver.Resolve();
            return await _dbContext.Set<InprotechKaizen.Model.Cases.AssignmentRecordal.RecordalType>()
                                   .Select(_ => new RecordalTypeItems
                                   {
                                       Id = _.Id,
                                       RecordalType = _.RecordalTypeName,
                                       RequestEvent = _.RequestEvent != null ? DbFuncs.GetTranslation(_.RequestEvent.Description, null, _.RequestEvent.DescriptionTId, culture) : null,
                                       RequestAction = _.RequestAction != null ? DbFuncs.GetTranslation(_.RequestAction.Name, null, _.RequestAction.NameTId, culture) : null,
                                       RecordalEvent = _.RecordEvent != null ? DbFuncs.GetTranslation(_.RecordEvent.Description, null, _.RecordEvent.DescriptionTId, culture) : null,
                                       RecordalAction = _.RecordAction != null ? DbFuncs.GetTranslation(_.RecordAction.Name, null, _.RecordAction.NameTId, culture) : null
                                   }).ToArrayAsync();
        }

        public async Task<RecordalTypeModel> GetRecordalTypeForm(int id)
        {
            var culture = _preferredCultureResolver.Resolve();
            var recordal = await _dbContext.Set<InprotechKaizen.Model.Cases.AssignmentRecordal.RecordalType>().Where(x => x.Id == id)
                                           .Select(type => new RecordalTypeModel
                                           {
                                               Id = type.Id,
                                               RecordalType = type.RecordalTypeName,
                                               RecordalAction = type.RecordActionId != null ? new Action { Key = type.RecordAction.Id, Code = type.RecordActionId, Value = DbFuncs.GetTranslation(type.RecordAction.Name, null, type.RecordAction.NameTId, culture) } : null,
                                               RequestAction = type.RequestActionId != null ? new Action { Key = type.RequestAction.Id, Code = type.RequestActionId, Value = DbFuncs.GetTranslation(type.RequestAction.Name, null, type.RequestAction.NameTId, culture) } : null,
                                               RequestEvent = type.RequestEventId != null ? new Event { Key = (int)type.RequestEventId, Value = DbFuncs.GetTranslation(type.RequestEvent.Description, null, type.RequestEvent.DescriptionTId, culture) } : null,
                                               RecordalEvent = type.RecordEventId != null ? new Event { Key = (int)type.RecordEventId, Value = DbFuncs.GetTranslation(type.RecordEvent.Description, null, type.RecordEvent.DescriptionTId, culture) } : null
                                           }).FirstOrDefaultAsync();

            if (recordal == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            recordal.Elements = await _dbContext.Set<RecordalElement>().Where(x => x.TypeId == id)
                                                    .Select(x => new RecordalElementsModel
                                                    {
                                                        Id = x.Id,
                                                        Element = x.Element != null ? new DropDown { Key = x.ElementId, Value = x.Element.Name } : null,
                                                        ElementLabel = x.ElementLabel,
                                                        NameType = x.NameTypeCode != null ? new NameTypeModel { Key = x.NameType.Id, Value = DbFuncs.GetTranslation(x.NameType.Name, null, x.NameType.NameTId, culture), Code = x.NameTypeCode } : null,
                                                        Attribute = x.EditAttribute
                                                    }).ToArrayAsync();

            return recordal;
        }

        public async Task<dynamic> Delete(int id)
        {
            var isInUse = false;

            var recordalType = await _dbContext.Set<InprotechKaizen.Model.Cases.AssignmentRecordal.RecordalType>().FirstOrDefaultAsync(_ => id == _.Id);
            if (recordalType == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            try
            {
                _dbContext.Set<InprotechKaizen.Model.Cases.AssignmentRecordal.RecordalType>().Remove(recordalType);
                await _dbContext.SaveChangesAsync();
            }
            catch (Exception e)
            {
                var sqlException = e.FindInnerException<SqlException>();
                if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                {
                    isInUse = true;
                }

                _dbContext.Detach(recordalType);
            }

            return isInUse ? new { Result = "inUse" } : new { Result = "success" };
        }

        public async Task<RecordalElementsModel> GetRecordalElementForm(int id)
        {
            var culture = _preferredCultureResolver.Resolve();
            var element = await _dbContext.Set<RecordalElement>().Include(x => x.Element).Where(x => x.Id == id)
                                          .Select(x => new RecordalElementsModel
                                          {
                                              Id = x.Id,
                                              Element = x.Element != null ? new DropDown { Key = x.ElementId, Value = x.Element.Name } : null,
                                              ElementLabel = x.ElementLabel,
                                              NameType = x.NameTypeCode != null ? new NameTypeModel { Key = x.NameType.Id, Value = DbFuncs.GetTranslation(x.NameType.Name, null, x.NameType.NameTId, culture), Code = x.NameTypeCode } : null,
                                              Attribute = x.EditAttribute
                                          }).FirstAsync();

            return element;
        }

        public async Task<dynamic> GetAllElements()
        {
            return await _dbContext.Set<Element>().Select(x => new
            {
                Key = x.Id,
                Value = x.Name,
                Attribute = x.EditAttribute
            }).ToArrayAsync();
        }

        public async Task<dynamic> SubmitRecordalTypeForm(RecordalTypeRequest model)
        {
            if (model == null)
                throw new HttpResponseException(HttpStatusCode.NotFound);

            var errors = await ValidateRecordalTypes(model);
            if (errors != null)
            {
                return errors;
            }

            var type = await GetRecordalTypeEntity(model);
            if (model.Status == KnownModifyStatus.Add)
            {
                _dbContext.Set<InprotechKaizen.Model.Cases.AssignmentRecordal.RecordalType>().Add(type);
                foreach (var el in model.Elements)
                {
                    var element = await GetRecordalElement(el, type, el.Status);
                    _dbContext.Set<RecordalElement>().Add(element);
                }
            }
            else if (model.Status == KnownModifyStatus.Edit)
            {
                foreach (var el in model.Elements)
                {
                    var element = await GetRecordalElement(el, type, el.Status);
                    if (el.Status == KnownModifyStatus.Add)
                    {
                        _dbContext.Set<RecordalElement>().Add(element);
                    }
                    if (el.Status == KnownModifyStatus.Delete)
                    {
                        _dbContext.Set<RecordalElement>().Remove(element);
                    }
                }
            }

            await _dbContext.SaveChangesAsync();

            return new {type.Id};
        }

        async Task<ValidationError> ValidateRecordalTypes(RecordalTypeRequest currentRow)
        {
            var allRecordalTypes = await _dbContext.Set<InprotechKaizen.Model.Cases.AssignmentRecordal.RecordalType>()
                                                   .Where(x => x.Id != currentRow.Id).ToListAsync();

            if (allRecordalTypes.Any(_ => _.RecordalTypeName == currentRow.RecordalType))
            {
                return ValidationErrors.SetCustomError("recordalType",
                                                       "field.errors.duplicateRecordalType", null, true);
            }

            return null;
        }

        async Task<InprotechKaizen.Model.Cases.AssignmentRecordal.RecordalType> GetRecordalTypeEntity(RecordalTypeRequest model)
        {
            var recordAction = await _dbContext.Set<InprotechKaizen.Model.Cases.Action>().FirstOrDefaultAsync(x => x.Code == model.RecordalAction);
            var requestAction = await _dbContext.Set<InprotechKaizen.Model.Cases.Action>().FirstOrDefaultAsync(x => x.Code == model.RequestAction);
            var recordEvent = await _dbContext.Set<InprotechKaizen.Model.Cases.Events.Event>().FirstOrDefaultAsync(x => x.Id == model.RecordalEvent);
            var requestEvent = await _dbContext.Set<InprotechKaizen.Model.Cases.Events.Event>().FirstOrDefaultAsync(x => x.Id == model.RequestEvent);
            if (model.Status == KnownModifyStatus.Add)
            {
                return new InprotechKaizen.Model.Cases.AssignmentRecordal.RecordalType
                {
                    RecordalTypeName = model.RecordalType,
                    RecordActionId = recordAction?.Code,
                    RecordEventId = recordEvent?.Id,
                    RequestEventId = requestEvent?.Id,
                    RequestActionId = requestAction?.Code
                };
            }

            var type = await _dbContext.Set<InprotechKaizen.Model.Cases.AssignmentRecordal.RecordalType>().FirstAsync(x => x.Id == model.Id);
            type.Id = model.Id;
            type.RecordalTypeName = model.RecordalType;
            type.RecordActionId = recordAction?.Code;
            type.RecordEventId = recordEvent?.Id;
            type.RequestEventId = requestEvent?.Id;
            type.RequestActionId = requestAction?.Code;
            return type;
        }

        async Task<RecordalElement> GetRecordalElement(RecordalElementRequest el, InprotechKaizen.Model.Cases.AssignmentRecordal.RecordalType type, string state)
        {
            var element = await _dbContext.Set<RecordalElement>().FirstOrDefaultAsync(x => x.Id == el.Id);
            switch (state)
            {
                case KnownModifyStatus.Edit:
                    if (element == null) return null;
                    element.EditAttribute = el.Attribute;
                    element.NameTypeCode = el.NameType;
                    element.ElementId = el.Element;
                    element.RecordalType = type;
                    element.ElementLabel = el.ElementLabel;
                    return element;
                case KnownModifyStatus.Delete:
                    return element;
                default:
                    return new RecordalElement
                    {
                        EditAttribute = el.Attribute,
                        NameTypeCode = el.NameType,
                        ElementId = el.Element,
                        ElementLabel = el.ElementLabel,
                        RecordalType = type
                    };
            }
        }
    }
}