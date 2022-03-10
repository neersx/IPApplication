using System;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Tests.Web.Builders.Model.Rules
{
    public class CriteriaBuilder : IBuilder<Criteria>
    {
        public int? Id { get; set; }
        public string Description { get; set; }
        public Action Action { get; set; }
        public string PurposeCode { get; set; }
        public CaseType CaseType { get; set; }
        public string CountryId { get; set; }
        public Country Country { get; set; }
        public decimal? UserDefinedRule { get; set; }
        public decimal? RuleInUse { get; set; }

        public Office Office { get; set; }
        public PropertyType PropertyType { get; set; }
        public CaseCategory CaseCategory { get; set; }
        public SubType SubType { get; set; }
        public ApplicationBasis Basis { get; set; }
        public DateTime? DateOfLaw { get; set; }
        public TableCode TableCode { get; set; }

        public int? LocalClientFlag { get; set; }
        public int? ParentCriteriaId { get; set; }

        public Criteria Build()
        {
            return new Criteria
            {
                Id = Id ?? Fixture.Integer(),
                Description = Description ?? Fixture.String("Description"),
                Action = Action,
                ActionId = Action?.Code,
                CaseTypeId = CaseType == null ? Fixture.RandomString(1) : CaseType.Code,
                PurposeCode = PurposeCode ?? Fixture.String("PurposeCode"),
                CountryId = Country == null ? Fixture.RandomString(3) : Country.Id,
                Country = Country,
                UserDefinedRule = UserDefinedRule,
                RuleInUse = RuleInUse,
                Office = Office,
                CaseType = CaseType,
                PropertyType = PropertyType,
                PropertyTypeId = PropertyType?.Code,
                CaseCategory = CaseCategory,
                CaseCategoryId = CaseCategory?.CaseCategoryId,
                SubType = SubType,
                Basis = Basis,
                DateOfLaw = DateOfLaw,
                LocalClientFlag = LocalClientFlag,
                ParentCriteriaId = ParentCriteriaId,
                TableCodeId = TableCode?.Id,
                TableCode = TableCode
            };
        }
    }

    public static class CriteriaBuilderExt
    {
        public static WorkflowSearchListItem AsCriteriaSearchListItem(this Criteria c)
        {
            var r = new WorkflowSearchListItem
            {
                Id = c.Id,
                CriteriaName = c.Description,
                DateOfLaw = c.DateOfLaw,
                IsLocalClient = c.IsLocalClient.GetValueOrDefault(),
                InUse = c.InUse,
                IsProtected = c.IsProtected
            };

            if (c.Office != null)
            {
                r.OfficeCode = c.Office.Id;
                r.OfficeDescription = c.Office.Name;
            }

            if (c.CaseType != null)
            {
                r.CaseTypeCode = c.CaseType.Code;
                r.CaseTypeDescription = c.CaseType.Name;
            }

            if (c.Country != null)
            {
                r.JurisdictionCode = c.Country.Id;
                r.JurisdictionDescription = c.Country.Name;
            }

            if (c.PropertyType != null)
            {
                r.PropertyTypeCode = c.PropertyType.Code;
                r.PropertyTypeDescription = c.PropertyType.Name;
            }

            if (c.CaseCategory != null)
            {
                r.CaseCategoryCode = c.CaseCategory.CaseCategoryId;
                r.CaseCategoryDescription = c.CaseCategory.Name;
            }

            if (c.SubType != null)
            {
                r.SubTypeCode = c.SubType.Code;
                r.SubTypeDescription = c.SubType.Name;
            }

            if (c.Basis != null)
            {
                r.BasisCode = c.Basis.Code;
                r.BasisDescription = c.Basis.Name;
            }

            if (c.Action != null)
            {
                r.ActionCode = c.Action.Code;
                r.ActionDescription = c.Action.Name;
            }

            return r;
        }
        
        public static CriteriaBuilder ForEventsEntriesRule(this CriteriaBuilder criteriaBuilder)
        {
            criteriaBuilder.PurposeCode = CriteriaPurposeCodes.EventsAndEntries;
            criteriaBuilder.RuleInUse ??= 1;
            criteriaBuilder.UserDefinedRule ??= 1;
            return criteriaBuilder;
        }

        public static CriteriaBuilder ForWindowControl(this CriteriaBuilder criteriaBuilder)
        {
            criteriaBuilder.PurposeCode = CriteriaPurposeCodes.WindowControl;
            criteriaBuilder.RuleInUse ??= 1;
            criteriaBuilder.UserDefinedRule ??= 1;
            return criteriaBuilder;
        }

        public static CriteriaBuilder ForChecklist(this CriteriaBuilder criteriaBuilder)
        {
            criteriaBuilder.PurposeCode = CriteriaPurposeCodes.CheckList;
            criteriaBuilder.RuleInUse ??= 1;
            criteriaBuilder.UserDefinedRule ??= 1;
            return criteriaBuilder;
        }

        public static CriteriaBuilder WithAction(this CriteriaBuilder criteriaBuilder, Action action = null)
        {
            criteriaBuilder.Action = action ?? new ActionBuilder().Build();
            return criteriaBuilder;
        }

        public static CriteriaBuilder WithOffice(this CriteriaBuilder criteriaBuilder, Office office = null)
        {
            criteriaBuilder.Office = office ?? new OfficeBuilder().Build();
            return criteriaBuilder;
        }

        public static CriteriaBuilder WithPropertyType(this CriteriaBuilder criteriaBuilder,
                                                       PropertyType propertyType = null)
        {
            criteriaBuilder.PropertyType = propertyType ?? new PropertyTypeBuilder().Build();
            return criteriaBuilder;
        }

        public static CriteriaBuilder WithCaseCategory(this CriteriaBuilder criteriaBuilder,
                                                       CaseCategory caseCategory = null)
        {
            criteriaBuilder.CaseCategory = caseCategory ??
                                           new CaseCategory(Fixture.String(), Fixture.String(), Fixture.String());
            return criteriaBuilder;
        }

        public static CriteriaBuilder WithSubType(this CriteriaBuilder criteriaBuilder, SubType subType = null)
        {
            criteriaBuilder.SubType = subType ?? new SubType(Fixture.String(), Fixture.String());
            return criteriaBuilder;
        }

        public static CriteriaBuilder WithBasis(this CriteriaBuilder criteriaBuilder, ApplicationBasis basis = null)
        {
            criteriaBuilder.Basis = basis ?? new ApplicationBasisBuilder().Build();
            return criteriaBuilder;
        }

        public static CriteriaBuilder WithDateOfLaw(this CriteriaBuilder criteriaBuilder, DateTime? dateOfLaw = null)
        {
            criteriaBuilder.DateOfLaw = dateOfLaw ?? Fixture.PastDate();
            return criteriaBuilder;
        }

        public static CriteriaBuilder WithCaseType(this CriteriaBuilder criteriaBuilder, CaseType caseType = null)
        {
            criteriaBuilder.CaseType = caseType ?? new CaseTypeBuilder().Build();
            return criteriaBuilder;
        }

        public static CriteriaBuilder WithCountry(this CriteriaBuilder criteriaBuilder, Country country = null)
        {
            criteriaBuilder.Country = country ?? new CountryBuilder().Build();
            return criteriaBuilder;
        }

        public static CriteriaBuilder WithExaminationType(this CriteriaBuilder criteriaBuilder, TableCode examinationType = null)
        {
            criteriaBuilder.TableCode = examinationType ?? new TableCode(Fixture.Integer(), (short) TableTypes.ExaminationType, Fixture.String());
            return criteriaBuilder;
        }

        public static CriteriaBuilder WithRenewalType(this CriteriaBuilder criteriaBuilder, TableCode renewalType = null)
        {
            criteriaBuilder.TableCode = renewalType ?? new TableCode(Fixture.Integer(), (short) TableTypes.RenewalType, Fixture.String());
            return criteriaBuilder;
        }
    }
}