using System;
using System.Linq;
using Inprotech.Web.Cases.AssignmentRecordal;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Cases.Maintenance.Updaters
{
    public class AffectedCasesTopicUpdater : ITopicDataUpdater<Case>
    {
        readonly IDbContext _dbContext;
        readonly IAssignmentRecordalHelper _helper;

        public AffectedCasesTopicUpdater(IDbContext dbContext, IAssignmentRecordalHelper helper)
        {
            _dbContext = dbContext;
            _helper = helper;
        }
        public void UpdateData(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
            var affectedMainCases = _dbContext.Set<RecordalAffectedCase>().Where(_ => _.CaseId == @case.Id);
            var maxSeq = affectedMainCases.Any() ? affectedMainCases.Max(_ => _.SequenceNo) : -1;
            var data = topicData["rows"].ToList().GroupBy(_ => _["rowKey"]);
            _helper.GetAssignmentRecordalRelationship(@case, out var relationship, out var reverseRelationship);
            foreach (var groupedData in data)
            {
                var counter = 1;
                var rowsRemoved = 1;
                foreach (var rowData in groupedData)
                {
                    var rowKey = rowData["rowKey"].Value<string>();
                    var step = "step" + counter;
                    var rowStep = rowData[step].Value<Boolean>();

                    var key = rowKey.Split('^');
                    var mainCaseId = int.Parse(key[0]);
                    var isInternal = int.TryParse(key[1], out int relatedCaseId);
                    var countryCode = key[2];
                    var officialNo = key[3];
                    var recordalStep = _dbContext.Set<RecordalStep>()
                                                  .FirstOrDefault(_ => _.CaseId == mainCaseId && _.StepId == counter);
                    var affectedCase = _dbContext.Set<RecordalAffectedCase>()
                                                 .FirstOrDefault(_ => _.CaseId == mainCaseId
                                                                      && (isInternal && relatedCaseId == _.RelatedCaseId
                                                                          || !isInternal && _.CountryId == countryCode && _.OfficialNumber == officialNo)
                                                                      && _.RecordalTypeNo == recordalStep.RecordalType.Id
                                                                      && _.RecordalStepSeq == recordalStep.Id);
                    var newNameRecordalElement = _dbContext.Set<RecordalStepElement>().FirstOrDefault(_ => _.RecordalStepId == recordalStep.Id
                                                                                                           && _.CaseId == @case.Id
                                                                                                           && _.EditAttribute == KnownRecordalEditAttributes.Mandatory
                                                                                                           && _.Element.Code == KnownRecordalElementValues.NewName
                                                                                                           && _.NameTypeCode == KnownNameTypes.Owner);

                    if(!rowStep) rowsRemoved++;

                    if (rowStep && affectedCase == null)
                    {
                        AddNewAffectedCase(isInternal, relatedCaseId, recordalStep, ++maxSeq, countryCode, officialNo, relationship, reverseRelationship, newNameRecordalElement?.ElementValue, counter - 1);
                    }
                    else if (!rowStep && affectedCase != null && affectedCase.Status == AffectedCaseStatus.NotYetFiled)
                    {
                        RemoveAffectedCase(affectedCase, newNameRecordalElement?.ElementValue);
                    }
                    counter++;
                }

                if (counter == rowsRemoved)
                {
                    RemoveRelatedCase(groupedData.Key.ToString(), relationship, reverseRelationship);
                }
            }

            void AddNewAffectedCase(bool isInternal, int relatedCaseId, RecordalStep recordalStep, int i, string countryCode, string officialNo, CaseRelation relation, CaseRelation reverseRelation, string owners, int counter)
            {
                if (isInternal)
                {
                    var relatedCase = _dbContext.Set<Case>().FirstOrDefault(x => x.Id == relatedCaseId);
                    if (recordalStep == null) return;

                    _dbContext.Set<RecordalAffectedCase>().Add(new RecordalAffectedCase(@case, relatedCase, i, recordalStep.RecordalType, recordalStep.Id, AffectedCaseStatus.NotYetFiled));
                    
                    _helper.AddRelatedCase(@case, relatedCase, null, null, relation, reverseRelation, counter);
                   
                    if (!string.IsNullOrWhiteSpace(owners))
                    {
                        _helper.AddNewOwners(relatedCase, owners);
                    }
                }
                else
                {
                    var country = _dbContext.Set<Country>().FirstOrDefault(x => x.Id == countryCode);
                    if (recordalStep == null) return;

                    _dbContext.Set<RecordalAffectedCase>().Add(new RecordalAffectedCase(@case, recordalStep.RecordalType, country, officialNo, recordalStep.Id, ++i, AffectedCaseStatus.NotYetFiled));
                    _helper.AddRelatedCase(@case, null, country?.Id, officialNo, relationship, null, counter);
                }
            }

            void RemoveAffectedCase(RecordalAffectedCase affectedCase, string owners)
            {
                if (affectedCase.RelatedCaseId.HasValue)
                {
                    _helper.RemoveNewOwners(affectedCase.RelatedCase, owners);
                }

                _dbContext.Set<RecordalAffectedCase>().Remove(affectedCase);
            }

            void RemoveRelatedCase(string groupedKey, CaseRelation relation, CaseRelation reverseRelation)
            {
                var key = groupedKey.Split('^');
                var isInternal = int.TryParse(key[1], out int relatedCaseId);
                var relatedCase = isInternal ? _dbContext.Set<Case>().First(_ => _.Id == relatedCaseId) : null;
                _helper.RemoveRelatedCase(@case, relatedCase, key[2], key[3], relation, reverseRelation);
            }
        }

        public void PostSaveData(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
        }
    }
}

