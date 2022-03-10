using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration.KeepOnTopNotes;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.KeepOnTopNotes
{
    public interface IKeepOnTopTextTypes
    {
        IEnumerable<KotTextType> GetKotTextTypes(string type, KeepOnTopSearchOptions searchOptions = null);
        Task<KotTextTypeData> GetKotTextTypeDetails(int id, string type);
        Task<KotSaveResponse> SaveKotTextType(KotTextTypeData kot, string type);
        Task<DeleteResponse> DeleteKotTextType(int id);
    }

    public class KeepOnTopTextTypes : IKeepOnTopTextTypes
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IStaticTranslator _staticTranslator;

        public KeepOnTopTextTypes(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IStaticTranslator staticTranslator)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _staticTranslator = staticTranslator;
        }

        public IEnumerable<KotTextType> GetKotTextTypes(string type, KeepOnTopSearchOptions searchOptions = null)
        {
            if (string.IsNullOrEmpty(type))
            {
                type = KnownKotTypes.Case;
            }

            var culture = _preferredCultureResolver.Resolve();
            var translatedCollection = GetTranslatedValue();
            var allKotTypes = _dbContext.Set<KeepOnTopTextType>().Where(_ => _.Type == type)
                                        .Select(_ => new
                                        {
                                            kot = _,
                                            TextType = DbFuncs.GetTranslation(_.TextType.TextDescription, null, _.TextType.TextDescriptionTId, culture),
                                            CaseTypes = _.KotCaseTypes.Select(ct => DbFuncs.GetTranslation(ct.CaseType.Name, null, ct.CaseType.NameTId, culture)),
                                            NameTypes = _.KotNameTypes.Select(ct => DbFuncs.GetTranslation(ct.NameType.Name, null, ct.NameType.NameTId, culture)),
                                            Roles = _.KotRoles.Select(rt => DbFuncs.GetTranslation(rt.Role.RoleName, null, rt.Role.RoleNameTId, culture))
                                        }).ToArray();

            var result = allKotTypes.Select(_ => new KotTextType
            {
                Id = _.kot.Id,
                TextType = _.TextType,
                CaseTypes = _.CaseTypes != null && type == KnownKotTypes.Case ? string.Join(", ", _.CaseTypes) : string.Empty,
                NameTypes = _.NameTypes != null && type == KnownKotTypes.Name ? string.Join(", ", _.NameTypes) : string.Empty,
                Roles = _.Roles != null ? string.Join(", ", _.Roles) : string.Empty,
                Modules = GetModules(_.kot, translatedCollection),
                StatusSummary = type == KnownKotTypes.Case ? GetCaseStatus(_.kot, translatedCollection) : null,
                BackgroundColor = _.kot.BackgroundColor
            });

            if (searchOptions?.Modules != null && searchOptions.Modules.Any())
            {
                result = result.Where(s => s.Modules != null && s.Modules.Split(',').Select(x => x.Trim()).Any(c => searchOptions.Modules.Contains(c)));
            }

            if (searchOptions?.Statuses != null && searchOptions.Statuses.Any())
            {
                result = result.Where(_ => _.StatusSummary != null && _.StatusSummary.Split(',').Select(x => x.Trim()).Any(t => searchOptions.Statuses.Contains(t)));
            }

            if (searchOptions?.Roles != null && searchOptions.Roles.Any())
            {
                result = result.Where(s => s.Roles != null && s.Roles.Split(',').Select(x => x.Trim()).Any(c => searchOptions.Roles.Contains(c)));
            }

            return result;
        }

        public async Task<KotTextTypeData> GetKotTextTypeDetails(int id, string type)
        {
            var kot = await _dbContext.Set<KeepOnTopTextType>().FirstOrDefaultAsync(_ => _.Id == id);
            if (kot == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            if (string.IsNullOrEmpty(type))
            {
                type = KnownKotTypes.Case;
            }

            var culture = _preferredCultureResolver.Resolve();

            return new KotTextTypeData
            {
                Id = kot.Id,
                TextType = new TextType {Key = kot.TextTypeId, Value = DbFuncs.GetTranslation(kot.TextType.TextDescription, null, kot.TextType.TextDescriptionTId, culture)},
                CaseTypes = type == KnownKotTypes.Case
                    ? kot.KotCaseTypes?.Select(ct => new CaseType {Key = ct.CaseType.Id, Code = ct.CaseTypeId, Value = DbFuncs.GetTranslation(ct.CaseType.Name, null, ct.CaseType.NameTId, culture)})
                    : null,
                NameTypes = type == KnownKotTypes.Name
                    ? kot.KotNameTypes?.Select(ct => new NameTypeModel {Key = ct.NameType.Id, Code = ct.NameTypeId, Value = DbFuncs.GetTranslation(ct.NameType.Name, null, ct.NameType.NameTId, culture)})
                    : null,
                Roles = kot.KotRoles?.Select(r => new RolesPicklistController.RolesPicklistItem {Key = r.RoleId, Value = DbFuncs.GetTranslation(r.Role.RoleName, null, r.Role.RoleNameTId, culture)}),
                HasCaseProgram = kot.CaseProgram,
                HasNameProgram = kot.NameProgram,
                HasTimeProgram = kot.TimeProgram,
                HasBillingProgram = kot.BillingProgram,
                HasTaskPlannerProgram = kot.TaskPlannerProgram,
                IsPending = kot.IsPending,
                IsRegistered = kot.IsRegistered,
                IsDead = kot.IsDead,
                BackgroundColor = kot.BackgroundColor
            };
        }

        public async Task<KotSaveResponse> SaveKotTextType(KotTextTypeData kot, string type)
        {
            if (kot == null) throw new ArgumentNullException(nameof(kot));

            var error = ValidateKotTextType(kot);
            if (error != null)
            {
                return new KotSaveResponse
                {
                    Error = error
                };
            }

            if (string.IsNullOrEmpty(type))
            {
                type = KnownKotTypes.Case;
            }

            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var keepOnTopTextType = _dbContext.Set<KeepOnTopTextType>().FirstOrDefault(_ => _.Id == kot.Id);
                if (keepOnTopTextType == null)
                {
                    keepOnTopTextType = new KeepOnTopTextType {Type = type};
                    _dbContext.Set<KeepOnTopTextType>().Add(keepOnTopTextType);
                }
                else
                {
                    RemoveExistingKotCollections(keepOnTopTextType);
                }

                keepOnTopTextType.TextTypeId = kot.TextType.Key;
                keepOnTopTextType.BackgroundColor = kot.BackgroundColor;
                keepOnTopTextType.IsRegistered = type == KnownKotTypes.Case && kot.IsRegistered;
                keepOnTopTextType.IsPending = type == KnownKotTypes.Case && kot.IsPending;
                keepOnTopTextType.IsDead = type == KnownKotTypes.Case && kot.IsDead;
                keepOnTopTextType.CaseProgram = kot.HasCaseProgram;
                keepOnTopTextType.NameProgram = kot.HasNameProgram;
                keepOnTopTextType.TimeProgram = kot.HasTimeProgram;
                keepOnTopTextType.BillingProgram = kot.HasBillingProgram;
                keepOnTopTextType.TaskPlannerProgram = kot.HasTaskPlannerProgram;
                AddKotCollections(kot, type, keepOnTopTextType);

                await _dbContext.SaveChangesAsync();
                tcs.Complete();

                return new KotSaveResponse
                {
                    Id = keepOnTopTextType.Id
                };
            }
        }

        public async Task<DeleteResponse> DeleteKotTextType(int id)
        {
            var keepOnTopTextType = _dbContext.Set<KeepOnTopTextType>().FirstOrDefault(_ => _.Id == id);
            if (keepOnTopTextType == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            _dbContext.Set<KeepOnTopTextType>().Remove(keepOnTopTextType);
            await _dbContext.SaveChangesAsync();
            return new DeleteResponse {Result = "success"};
        }

        ValidationError ValidateKotTextType(KotTextTypeData kot)
        {
            var hasDuplicateTextType = _dbContext.Set<KeepOnTopTextType>().Any(_ => _.TextTypeId == kot.TextType.Key && _.Id != kot.Id);
            return hasDuplicateTextType ? ValidationErrors.SetError("textType", "field.errors.duplicateTextType") : null;
        }

        void RemoveExistingKotCollections(KeepOnTopTextType keepOnTopTextType)
        {
            if (keepOnTopTextType.KotRoles.Any())
            {
                _dbContext.RemoveRange(keepOnTopTextType.KotRoles);
            }

            if (keepOnTopTextType.KotCaseTypes.Any())
            {
                _dbContext.RemoveRange(keepOnTopTextType.KotCaseTypes);
            }

            if (keepOnTopTextType.KotNameTypes.Any())
            {
                _dbContext.RemoveRange(keepOnTopTextType.KotNameTypes);
            }
        }

        void AddKotCollections(KotTextTypeData kot, string type, KeepOnTopTextType keepOnTopTextType)
        {
            if (kot.Roles != null)
            {
                _dbContext.AddRange(kot.Roles.Select(_ => new KeepOnTopRole {KotTextTypeId = keepOnTopTextType.Id, RoleId = _.Key}));
            }

            if (type == KnownKotTypes.Case && kot.CaseTypes != null)
            {
                _dbContext.AddRange(kot.CaseTypes.Select(_ => new KeepOnTopCaseType {KotTextTypeId = keepOnTopTextType.Id, CaseTypeId = _.Code}));
            }
            else if (kot.NameTypes != null)
            {
                _dbContext.AddRange(kot.NameTypes.Select(_ => new KeepOnTopNameType {KotTextTypeId = keepOnTopTextType.Id, NameTypeId = _.Code}));
            }
        }

        string GetModules(KeepOnTopTextType kot, IDictionary<string, string> translatedStrings)
        {
            if (kot == null) return null;

            var moduleList = new List<string>();
            if (kot.CaseProgram)
            {
                moduleList.Add(translatedStrings[KnownKotModules.Case]);
            }

            if (kot.NameProgram)
            {
                moduleList.Add(translatedStrings[KnownKotModules.Name]);
            }

            if (kot.TimeProgram)
            {
                moduleList.Add(translatedStrings[KnownKotModules.Time]);
            }

            if (kot.BillingProgram)
            {
                moduleList.Add(translatedStrings[KnownKotModules.Billing]);
            }

            if (kot.TaskPlannerProgram)
            {
                moduleList.Add(translatedStrings[KnownKotModules.TaskPlanner]);
            }

            return string.Join(", ", moduleList);
        }

        string GetCaseStatus(KeepOnTopTextType kot, IDictionary<string, string> translatedStrings)
        {
            if (kot == null) return null;

            var moduleList = new List<string>();

            if (kot.IsPending)
            {
                moduleList.Add(translatedStrings[KnownKotCaseStatus.Pending]);
            }

            if (kot.IsRegistered)
            {
                moduleList.Add(translatedStrings[KnownKotCaseStatus.Registered]);
            }

            if (kot.IsDead)
            {
                moduleList.Add(translatedStrings[KnownKotCaseStatus.Dead]);
            }

            return string.Join(", ", moduleList);
        }

        IDictionary<string, string> GetTranslatedValue()
        {
            var cultures = _preferredCultureResolver.ResolveAll().ToArray();
            var collection = new Dictionary<string, string>
            {
                {KnownKotCaseStatus.Registered, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.registered", cultures)},
                {KnownKotCaseStatus.Pending, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.pending", cultures)},
                {KnownKotCaseStatus.Dead, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.dead", cultures)},
                {KnownKotModules.Case, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.caseProgram", cultures)},
                {KnownKotModules.Name, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.nameProgram", cultures)},
                {KnownKotModules.Time, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.timeProgram", cultures)},
                {KnownKotModules.TaskPlanner, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.taskPlannerProgram", cultures)},
                {KnownKotModules.Billing, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.billingProgram", cultures)}
            };

            return collection;
        }
    }

    public class KotTextType
    {
        public int Id { get; set; }
        public string TextType { get; set; }
        public string CaseTypes { get; set; }
        public string NameTypes { get; set; }
        public string Modules { get; set; }
        public string Roles { get; set; }
        public string StatusSummary { get; set; }
        public string BackgroundColor { get; set; }
    }

    public class KotTextTypeData
    {
        public int? Id { get; set; }
        public TextType TextType { get; set; }
        public IEnumerable<CaseType> CaseTypes { get; set; }
        public IEnumerable<NameTypeModel> NameTypes { get; set; }
        public IEnumerable<RolesPicklistController.RolesPicklistItem> Roles { get; set; }
        public bool HasCaseProgram { get; set; }
        public bool HasNameProgram { get; set; }
        public bool HasTimeProgram { get; set; }
        public bool HasBillingProgram { get; set; }
        public bool HasTaskPlannerProgram { get; set; }
        public bool IsPending { get; set; }
        public bool IsRegistered { get; set; }
        public bool IsDead { get; set; }
        public string BackgroundColor { get; set; }
    }
}