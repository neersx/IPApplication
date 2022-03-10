using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using Name = Inprotech.Web.Picklists.Name;

namespace Inprotech.Web.Cases.AssignmentRecordal
{
    public interface IRecordalSteps
    {
        Task<IEnumerable<CaseRecordalStep>> GetRecordalSteps(int caseKey);
        Task<IEnumerable<CaseRecordalStepElement>> GetRecordalStepElement(int caseKey, RecordalStep recordalStep);
        Task<CurrentAddress> GetCurrentAddress(int nameId);
    }
    public class RecordalSteps : IRecordalSteps
    {
        readonly IDbContext _dbContext;
        readonly IFormattedNameAddressTelecom _formattedNameAddress;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IStaticTranslator _staticTranslator;

        public RecordalSteps(IDbContext dbContext, IFormattedNameAddressTelecom formattedNameAddress, IPreferredCultureResolver preferredCultureResolver, IStaticTranslator staticTranslator)
        {
            _dbContext = dbContext;
            _formattedNameAddress = formattedNameAddress;
            _preferredCultureResolver = preferredCultureResolver;
            _staticTranslator = staticTranslator;
        }
        public async Task<IEnumerable<CaseRecordalStep>> GetRecordalSteps(int caseKey)
        {
            var cultures = _preferredCultureResolver.ResolveAll().ToArray();
            var stepLabel = _staticTranslator.TranslateWithDefault("caseview.recordal.stepLabel", cultures);
            var result = await _dbContext.Set<RecordalStep>().Where(_ => _.CaseId == caseKey)
                                   .Select(_ => new CaseRecordalStep
                                   {
                                       CaseId = _.CaseId,
                                       Id = _.Id,
                                       StepId = _.StepId,
                                       StepName = stepLabel + " " + _.StepId,
                                       RecordalType = new RecordalTypePicklistItem { Key = _.RecordalType.Id, Value = _.RecordalType.RecordalTypeName },
                                       ModifiedDate = _.ModifiedDate,
                                   }).OrderBy(_ => _.StepId).ToArrayAsync();

            foreach (var r in result)
            {
                r.IsAssigned = _dbContext.Set<RecordalAffectedCase>().Any(_ => _.CaseId == r.CaseId && _.RecordalTypeNo == r.RecordalType.Key && (_.RecordalStepSeq == r.Id || _.RecordalStepSeq == null));
            }
            return result;
        }

        ElementType GetStepElementType(string elementCode)
        {
            if (elementCode.Contains("POSTAL"))
            {
                return ElementType.PostalAddress;
            }

            return elementCode.Contains("STREET") ? ElementType.StreetAddress : ElementType.Name;
        }
        public async Task<IEnumerable<CaseRecordalStepElement>> GetRecordalStepElement(int caseKey, RecordalStep recordalStep)
        {
            if (recordalStep == null) throw new ArgumentNullException(nameof(recordalStep));

            var culture = _preferredCultureResolver.Resolve();
            var hasRecordalType = recordalStep.RecordalType != null;
            var existingStepElements = from rse in _dbContext.Set<RecordalStepElement>().Where(_ => _.CaseId == caseKey && _.RecordalStepId == recordalStep.Id && hasRecordalType)
                                       join nte in _dbContext.Set<NameType>() on rse.NameTypeCode equals nte.NameTypeCode into nt1
                                       from nte in nt1.DefaultIfEmpty()
                                       select new
                                       {
                                           rse.ElementId,
                                           rse.NameTypeCode,
                                           nte.ShowNameCode,
                                           NameTypeName = nte.Name,
                                           NameTypeNameTId = nte.NameTId,
                                           nte.MaximumAllowed,
                                           rse.ElementLabel,
                                           rse.EditAttribute,
                                           rse.ElementValue,
                                           rse.OtherValue
                                       };

            var elements = await (from re in _dbContext.Set<RecordalElement>().Where(_ => _.TypeId == recordalStep.TypeId)
                                  join rse in existingStepElements on re.ElementId equals rse.ElementId into rse1
                                  from rse in rse1.DefaultIfEmpty()
                                  join nt in _dbContext.Set<NameType>() on re.NameTypeCode equals nt.NameTypeCode into nt1
                                  from nt in nt1.DefaultIfEmpty()
                                  select new CaseRecordalStepElement
                                  {
                                      CaseId = caseKey,
                                      Id = recordalStep.Id,
                                      StepId = recordalStep.StepId.ToString(),
                                      NameType = rse != null ? rse.NameTypeCode : re.NameTypeCode,
                                      ShowNameCode = (decimal)(rse != null ? rse.ShowNameCode : nt != null ? nt.ShowNameCode : 0),
                                      NameTypeValue = rse != null && rse.NameTypeCode != null ? DbFuncs.GetTranslation(rse.NameTypeName, null, rse.NameTypeNameTId, culture) : nt != null ?
                                          DbFuncs.GetTranslation(nt.Name, null, nt.NameTId, culture) : null,
                                      MaxNamesAllowed = rse != null ? rse.MaximumAllowed : nt != null ? nt.MaximumAllowed : null,
                                      ElementId = re.ElementId,
                                      Element = DbFuncs.GetTranslation(re.Element.Name, null, re.Element.NameTid, culture),
                                      Label = rse != null ? rse.ElementLabel : re.ElementLabel,
                                      EditAttribute = rse != null ? rse.EditAttribute : re.EditAttribute,
                                      TypeText = re.Element.Code,
                                      ValueId = rse != null ? rse.ElementValue : null,
                                      OtherValueId = rse != null ? rse.OtherValue : null
                                  }).OrderBy(_ => _.ElementId).ToArrayAsync();
            await SetFormattedNamesAndAddresses(elements);

            return elements;
        }

        public async Task<CurrentAddress> GetCurrentAddress(int nameId)
        {
            var names = await _formattedNameAddress.GetFormatted(new[] { nameId });
            var currentName = names.Get(nameId);

            var addressIds = new List<int>();
            if (currentName.MainStreetAddressId.HasValue)
                addressIds.Add(currentName.MainStreetAddressId.Value);
            if (currentName.MainPostalAddressId.HasValue)
                addressIds.Add(currentName.MainPostalAddressId.Value);

            if (!addressIds.Any())
            {
                return null;
            }

            var formattedAddresses = await _formattedNameAddress.GetAddressesFormatted(addressIds.Distinct().ToArray());
            return new CurrentAddress
            {
                NamePicklist = new Name
                {
                    Key = currentName.NameId,
                    Code = currentName.NameCode,
                    DisplayName = currentName.Name
                },
                StreetAddressPicklist = currentName.MainStreetAddressId.HasValue
                    ? new AddressPicklistItem
                    {
                        Id = currentName.MainStreetAddressId.Value,
                        Address = formattedAddresses.Get(currentName.MainStreetAddressId.Value)?.Address
                    }
                    : null,
                PostalAddressPicklist = currentName.MainPostalAddressId.HasValue
                    ? new AddressPicklistItem
                    {
                        Id = currentName.MainPostalAddressId.Value,
                        Address = formattedAddresses.Get(currentName.MainPostalAddressId.Value)?.Address
                    }
                    : null
            };
        }

        async Task SetFormattedNamesAndAddresses(IEnumerable<CaseRecordalStepElement> elements)
        {
            var recordalStepElements = elements as CaseRecordalStepElement[] ?? elements.ToArray();
            foreach (var ele in recordalStepElements)
            {
                ele.Type = GetStepElementType(ele.TypeText);
            }

            var caseRecordalStepElements = elements as CaseRecordalStepElement[] ?? recordalStepElements.ToArray();
            var names = caseRecordalStepElements.Where(_ => _.Type == ElementType.Name && _.ValueId != null).Select(_ => _.ValueId.Split(',')).SelectMany(_ => _).Select(_ => Convert.ToInt32(_)).ToList();
            var otherNames = caseRecordalStepElements.Where(_ => (_.Type == ElementType.PostalAddress || _.Type == ElementType.StreetAddress)
                                                                 && _.OtherValueId != null).Select(_ => Convert.ToInt32(_.OtherValueId)).ToList();
            if (names.Any() || otherNames.Any())
            {
                var formattedNames = await _formattedNameAddress.GetFormatted(names.Concat(otherNames).Distinct().ToArray());
                foreach (var se in caseRecordalStepElements)
                {
                    switch (se.Type)
                    {
                        case ElementType.Name when se.ValueId != null:
                            var nameLists = (from val in se.ValueId.Split(',')
                                             where !string.IsNullOrWhiteSpace(val)
                                             select Convert.ToInt32(val) into nameId
                                             let name = formattedNames.Get(nameId).Name
                                             let nameCode = formattedNames.Get(nameId).NameCode
                                             select new Name { Key = nameId, DisplayName = ((ShowNameCode) se.ShowNameCode).Format(name, nameCode) }).ToList();

                            se.Value = string.Join("; ", nameLists.Select(_ => _.DisplayName));
                            se.NamePicklist = nameLists.ToArray();
                            break;
                        case ElementType.StreetAddress when se.OtherValueId != null:
                        case ElementType.PostalAddress when se.OtherValueId != null:
                            var otherNameId = Convert.ToInt32(se.OtherValueId);
                            se.OtherValue = ((ShowNameCode) se.ShowNameCode).Format(formattedNames[otherNameId].Name, formattedNames[otherNameId].NameCode);
                            se.NamePicklist = new[] { new Name { Key = otherNameId, DisplayName = se.OtherValue } };
                            break;
                    }
                }
            }

            var addresses = caseRecordalStepElements.Where(_ => (_.Type == ElementType.PostalAddress || _.Type == ElementType.StreetAddress) && _.ValueId != null).Select(_ => Convert.ToInt32(_.ValueId)).ToList();
            var otherAddresses = caseRecordalStepElements.Where(_ => _.Type == ElementType.Name && _.OtherValueId != null).Select(_ => Convert.ToInt32(_.OtherValueId)).ToList();
            if (addresses.Any() || otherAddresses.Any())
            {
                var formattedAddresses = await _formattedNameAddress.GetAddressesFormatted(addresses.Concat(otherAddresses).Distinct().ToArray());
                foreach (var se in caseRecordalStepElements)
                {
                    switch (se.Type)
                    {
                        case ElementType.Name when se.OtherValueId != null:
                            var otherAddressId = Convert.ToInt32(se.OtherValueId);
                            se.OtherValue = formattedAddresses[otherAddressId].Address;
                            se.AddressPicklist = new AddressPicklistItem { Id = otherAddressId, Address = se.OtherValue };
                            break;
                        case ElementType.StreetAddress when se.ValueId != null:
                        case ElementType.PostalAddress when se.ValueId != null:
                            var addressId = Convert.ToInt32(se.ValueId);
                            se.Value = formattedAddresses[addressId].Address;
                            se.AddressPicklist = new AddressPicklistItem { Id = addressId, Address = se.Value };
                            break;
                    }
                }
            }
        }
    }

}
