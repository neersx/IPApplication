using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    public interface ICaseListMaintenance
    {
        IEnumerable<CaseList> GetCaseLists();

        CaseList GetCaseList(int caseListId);

        IEnumerable<CaseListItem> GetCases(IEnumerable<int> caseKeys, int? primeCaseKey, IEnumerable<int> newlyAddedCaseKeys);

        dynamic Update(int id, CaseList caseList);

        dynamic Save(CaseList caseList);

        dynamic Delete(int id);

        dynamic Delete(List<int> caseListIds);
    }

    public class CaseListMaintenance : ICaseListMaintenance
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public CaseListMaintenance(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        public IEnumerable<CaseList> GetCaseLists()
        {
            var culture = _preferredCultureResolver.Resolve();
            var caseList = _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>();
            var caseListMember = _dbContext.Set<CaseListMember>().Where(_ => _.IsPrimeCase);

            var caseLists = (from cl in caseList
                             join clm1 in caseListMember on cl.Id equals clm1.Id into clm2
                             from clm in clm2.DefaultIfEmpty()
                             select new CaseList
                             {
                                 Key = cl.Id,
                                 Value = DbFuncs.GetTranslation(cl.Name, null, cl.NameTId, culture),
                                 Description = DbFuncs.GetTranslation(cl.Description, null, cl.DescriptionTId, culture),
                                 PrimeCase = clm != null
                                     ? new Case
                                     {
                                         Key = clm.Case.Id,
                                         Code = clm.Case.Irn,
                                         Value = clm.Case.Irn
                                     }
                                     : null
                             }).ToArray();

            foreach (var cl in caseLists)
            {
                cl.CaseKeys = _dbContext.Set<CaseListMember>()
                                              .Where(_ => _.Id == cl.Key)
                                              .Select(x => x.CaseId).ToArray();
            }

            return caseLists;
        }

        public IEnumerable<CaseListItem> GetCases(IEnumerable<int> caseKeys, int? primeCaseKey, IEnumerable<int> newlyAddedCaseKeys)
        {
            var cases = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().Where(_ => caseKeys.Contains(_.Id));
            newlyAddedCaseKeys = newlyAddedCaseKeys ?? new List<int>();

            var list = cases.Select(_ => new CaseListItem()
            {
                CaseKey = _.Id,
                CaseRef = _.Irn,
                Title = _.Title,
                IsPrimeCase = primeCaseKey.HasValue && primeCaseKey.Value == _.Id,
                IsNewlyAddedCase = newlyAddedCaseKeys.Contains(_.Id),
                OfficialNumber = _.CurrentOfficialNumber
            }).OrderByDescending(_ => _.IsNewlyAddedCase).ThenBy(_ => _.CaseRef).ToList();

            return list;
        }

        public CaseList GetCaseList(int caseListId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var model = _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>().SingleOrDefault(_ => _.Id == caseListId);
            if (model == null) throw new ArgumentNullException(nameof(caseListId));
            var primeCaseListMember = _dbContext.Set<CaseListMember>().SingleOrDefault(_ => _.Id == caseListId && _.IsPrimeCase);

            var caseList = new CaseList
            {
                Key = model.Id,
                Value = DbFuncs.GetTranslation(model.Name, null, model.NameTId, culture),
                Description = DbFuncs.GetTranslation(model.Description, null, model.DescriptionTId, culture)
            };
            caseList.CaseKeys = _dbContext.Set<CaseListMember>()
                                          .Where(_ => _.Id == caseList.Key)
                                          .Select(x => x.CaseId).ToArray();
            if (primeCaseListMember == null) return caseList;
            var @case = primeCaseListMember.Case;
            caseList.PrimeCase = new Case
            {
                Key = @case.Id,
                Code = @case.Irn,
                Value = @case.Irn
            };

            return caseList;
        }

        public dynamic Update(int id, CaseList model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            var caseList = _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>().SingleOrDefault(_ => _.Id == id);
            if (caseList == null) throw new ArgumentNullException(nameof(id));

            return SaveData(model, id);
        }

        public dynamic Save(CaseList model)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (string.IsNullOrEmpty(model.Value)) throw new ArgumentNullException(model.Value);

            return SaveData(model);
        }

        dynamic SaveData(CaseList model, int? id = null)
        {
            using (var ts = _dbContext.BeginTransaction())
            {
                var validationErrors = Validate(model, !id.HasValue ? Operation.Add : Operation.Update);
                var enumerable = validationErrors as ValidationError[] ?? validationErrors.ToArray();
                if (enumerable.Any()) return enumerable.AsErrorResponse();

                InprotechKaizen.Model.Cases.CaseList modifiedCaseList;
                if (id.HasValue)
                {
                    modifiedCaseList = _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>().Single(_ => _.Id == id);
                    modifiedCaseList.Name = model.Value;
                    modifiedCaseList.Description = model.Description;

                    var existingCaseListMember = _dbContext.Set<CaseListMember>().Where(_ => _.Id == id);
                    if (existingCaseListMember.Any())
                    {
                        _dbContext.RemoveRange(existingCaseListMember);
                    }
                }
                else
                {
                    var newId = _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.CaseList);
                    modifiedCaseList = _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>()
                                                .Add(new InprotechKaizen.Model.Cases.CaseList(newId, model.Value)
                                                {
                                                    Description = model.Description
                                                });

                }
                _dbContext.SaveChanges();
                var caseKeys = model.CaseKeys.Distinct().ToList();
                if (model.PrimeCase != null && model.CaseKeys.All(_ => _ != model.PrimeCase.Key))
                {
                    caseKeys.Add(model.PrimeCase.Key);
                }

                if (caseKeys.Any())
                {
                    var newCaseListItems = caseKeys
                        .Select(_ =>
                                    new CaseListMember(modifiedCaseList.Id, _, model.PrimeCase != null && _ == model.PrimeCase.Key));
                    _dbContext.AddRange(newCaseListItems);
                }

                _dbContext.SaveChanges();
                ts.Complete();
                return new
                {
                    Result = "success",
                    UpdatedId = modifiedCaseList.Id,
                    Key = modifiedCaseList.Id
                };
            }
        }

        public dynamic Delete(int id)
        {
            var caseList = _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>().SingleOrDefault(_ => _.Id == id);
            if (caseList == null) throw new ArgumentNullException(nameof(id));
            using (var ts = _dbContext.BeginTransaction())
            {
                var caseListInPriorArt = _dbContext.Set<CaseListSearchResult>().Where(_ => _.CaseListId == id);
                var caseListInListMember = _dbContext.Set<CaseListMember>().Where(_ => !_.IsPrimeCase && _.Id == id);
                if (caseListInPriorArt.Any() || caseListInListMember.Any()) return KnownSqlErrors.CannotDelete.AsHandled();

                _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>().Remove(caseList);
                _dbContext.SaveChanges();
                ts.Complete();
                return new
                {
                    Result = "success"
                };
            }
        }

        public dynamic Delete(List<int> caseListIds)
        {
            if (caseListIds == null) throw new ArgumentNullException(nameof(caseListIds));

            var cannotDeleteCaselistIds = new List<int>();
            using (var ts = _dbContext.BeginTransaction())
            {
                foreach (var id in caseListIds)
                {
                    var caseList = _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>().SingleOrDefault(_ => _.Id == id);
                    var caseListInPriorArt = _dbContext.Set<CaseListSearchResult>().Where(_ => _.CaseListId == id);
                    var caseListInListMember = _dbContext.Set<CaseListMember>().Where(_ => !_.IsPrimeCase && _.Id == id);
                    if (caseListInPriorArt.Any() || caseListInListMember.Any())
                    {
                        cannotDeleteCaselistIds.Add(id);
                        continue;
                    }
                    _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>().Remove(caseList);
                }
                _dbContext.SaveChanges();
                ts.Complete();
            }

            var result = !cannotDeleteCaselistIds.Any() ? "success" : caseListIds.Count == cannotDeleteCaselistIds.Count ? "error" : "partialComplete";

            return new
            {
                Result = result,
                CannotDeleteCaselistIds = cannotDeleteCaselistIds
            };
        }

        bool IsDuplicate(CaseList model)
        {
            return _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>()
                             .Any(_ => _.Name.Equals(model.Value, StringComparison.InvariantCultureIgnoreCase) && _.Id != model.Key);
        }

        IEnumerable<ValidationError> Validate(CaseList caseList, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(caseList))
                yield return validationError;

            foreach (var vr in CheckForErrors(caseList, operation)) yield return vr;
        }

        IEnumerable<ValidationError> CheckForErrors(CaseList model, Operation operation)
        {
            var caseList = _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>().SingleOrDefault(_ => _.Id == model.Key);

            if (operation == Operation.Update && caseList == null)
            {
                throw new HttpResponseException(HttpStatusCode.NotFound);
            }

            if (!Enum.IsDefined(typeof(Operation), operation)) throw new InvalidEnumArgumentException(nameof(operation), (int)operation, typeof(Operation));

            if (IsDuplicate(model))
            {
                yield return ValidationErrors.NotUnique("value");
            }

            if (string.IsNullOrEmpty(model.Value))
            {
                yield return ValidationErrors.Required("value");
            }
        }

    }
}