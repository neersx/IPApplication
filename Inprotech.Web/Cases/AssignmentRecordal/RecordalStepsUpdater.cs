using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.AssignmentRecordal
{
    public interface IRecordalStepsUpdater
    {
        IEnumerable<ValidationError> Validate(IEnumerable<CaseRecordalStep> model);
        Task SubmitRecordalStep(IEnumerable<CaseRecordalStep> model);
    }
    public class RecordalStepsUpdater : IRecordalStepsUpdater
    {
        readonly IDbContext _dbContext;

        public RecordalStepsUpdater(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IEnumerable<ValidationError> Validate(IEnumerable<CaseRecordalStep> model)
        {
            var caseRecordalSteps = model as CaseRecordalStep[] ?? model.ToArray();
            if (!caseRecordalSteps.Any())
            {
                yield break;
            }

            if (caseRecordalSteps.All(_ => _.Status == KnownModifyStatus.Delete))
            {
                yield break;
            }
            var caseId = caseRecordalSteps[0].CaseId;
            var recordalTypes = _dbContext.Set<RecordalAffectedCase>().Where(_ => _.CaseId == caseId).Select(_ => _.RecordalTypeNo).Distinct().ToArray();
            var assignedRecordalTypes = _dbContext.Set<RecordalStep>().Where(_ => _.CaseId == caseId && recordalTypes.Contains(_.RecordalType.Id))
                                          .Select(_ => new
                                          {
                                              _.Id,
                                              RecordalType = _.RecordalType.Id
                                          }).ToArray();
            foreach (var entity in caseRecordalSteps.Where(_ => _.Status == KnownModifyStatus.Add || _.Status == KnownModifyStatus.Edit || _.Status == null))
            {
                if (entity.Status == KnownModifyStatus.Add || entity.Status == KnownModifyStatus.Edit)
                {
                    if (entity.RecordalType == null)
                    {
                        yield return ValidationErrors.SetCustomError(entity.StepName, "field.errors.recordal.recordalTypeNull", string.Empty, false);
                        yield break;
                    }
                }
                if (entity.CaseRecordalStepElements == null || !entity.CaseRecordalStepElements.Any() ||
                    entity.CaseRecordalStepElements.Any(_ => _.EditAttribute == KnownRecordalEditAttributes.Mandatory
                                                             && ((_.NamePicklist == null && _.Type == ElementType.Name)
                                                             || (_.AddressPicklist == null && (_.Type == ElementType.StreetAddress || _.Type == ElementType.PostalAddress)))))
                {
                    yield return ValidationErrors.SetCustomError(entity.StepName, "field.errors.recordal.required", string.Empty, false);
                }
            }
        }

        public async Task SubmitRecordalStep(IEnumerable<CaseRecordalStep> model)
        {
            foreach (var entity in model.OrderBy(_ => _.Status == KnownModifyStatus.Delete))
            {
                switch (entity.Status)
                {
                    case KnownModifyStatus.Add:
                        _dbContext.Set<RecordalStep>().Add(new RecordalStep { CaseId = entity.CaseId, TypeId = entity.RecordalType.Key, ModifiedDate = DateTime.Now, StepId = entity.StepId, Id = entity.Id });
                        AddRecordalElements(entity);
                        break;
                    case KnownModifyStatus.Edit:
                    case KnownModifyStatus.Delete:
                    {
                        var data = await _dbContext.Set<RecordalStep>().FirstOrDefaultAsync(x => x.CaseId == entity.CaseId && x.Id == entity.Id);
                        if (data != null)
                        {
                            if (entity.Status == KnownModifyStatus.Edit)
                            {
                                if (data.TypeId != entity.RecordalType.Key)
                                {
                                    data.TypeId = entity.RecordalType.Key;
                                    DeleteRecordalStepElements(data);
                                    AddRecordalElements(entity);
                                }
                            }
                            else if (entity.Status == KnownModifyStatus.Delete)
                            {
                                _dbContext.Set<RecordalStep>().Remove(data);
                                RearrangeStepNumbers(data);
                            }
                        }

                        break;
                    }
                    default:
                    {
                        if (entity.CaseRecordalStepElements != null && entity.CaseRecordalStepElements.Any())
                        {
                            foreach (var stepElement in entity.CaseRecordalStepElements.Where(_ => _.Status == KnownModifyStatus.Edit))
                            {
                                var ele = await _dbContext.Set<RecordalStepElement>().FirstOrDefaultAsync(_ => _.CaseId == entity.CaseId && _.RecordalStepId == entity.Id && _.ElementId == stepElement.ElementId);
                                if (ele == null) continue;

                                if (stepElement.Type == ElementType.Name)
                                {
                                    ele.ElementValue = stepElement.NamePicklist != null ? string.Join(",", stepElement.NamePicklist.Select(_ => _.Key)) : null;
                                }
                                else
                                {
                                    ele.ElementValue = stepElement.AddressPicklist?.Id.ToString();
                                    ele.OtherValue = stepElement.NamePicklist.FirstOrDefault()?.Key.ToString();
                                }
                            }
                        }

                        break;
                    }
                }
            }

            await _dbContext.SaveChangesAsync();
        }

        void DeleteRecordalStepElements(RecordalStep data)
        {
            var existingElements = _dbContext.Set<RecordalStepElement>().Where(_ => _.CaseId == data.CaseId && _.RecordalStepId == data.Id).ToArray();
            foreach (var ele in existingElements)
            {
                _dbContext.Set<RecordalStepElement>().Remove(ele);
            }
        }

        void AddRecordalElements(CaseRecordalStep entity)
        {
            if (entity.CaseRecordalStepElements != null)
            {
                foreach (var stepElement in entity.CaseRecordalStepElements)
                {
                    var element = new RecordalStepElement
                    {
                        ElementId = stepElement.ElementId,
                        CaseId = entity.CaseId,
                        RecordalStepId = entity.Id,
                        ElementLabel = stepElement.Label,
                        NameTypeCode = stepElement.NameType,
                        EditAttribute = stepElement.EditAttribute
                    };
                    if (stepElement.Type == ElementType.Name)
                    {
                        element.ElementValue = stepElement.NamePicklist != null ? string.Join(",", stepElement.NamePicklist.Select(_ => _.Key)) : null;
                    }
                    else
                    {
                        element.ElementValue = stepElement.AddressPicklist?.Id.ToString();
                        element.OtherValue = stepElement.NamePicklist?.FirstOrDefault()?.Key.ToString();
                    }
                    _dbContext.Set<RecordalStepElement>().Add(element);
                }
            }
        }

        void RearrangeStepNumbers(RecordalStep recordalStep)
        {
            var nextSteps = _dbContext.Set<RecordalStep>().Where(_ => _.StepId > recordalStep.StepId);
            foreach (var step in nextSteps)
            {
                step.StepId -= 1;
            }
        }
    }
}
