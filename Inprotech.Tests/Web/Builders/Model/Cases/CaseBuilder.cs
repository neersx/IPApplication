using System;
using System.Collections.Generic;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CaseBuilder : IBuilder<Case>
    {
        public string Irn { get; set; }
        public Country Country { get; set; }
        public string CountryCode { get; set; }
        public string CountryAdjective { get; set; }
        public CaseType CaseType { get; set; }
        public SubType SubType { get; set; }
        public PropertyType PropertyType { get; set; }
        public Office Office { get; set; }
        public bool IsPrimeCase { get; set; }
        public Status Status { get; set; }
        public CaseProperty Property { get; set; }
        public bool HasNoDefaultStatus { get; set; }
        public bool HasNoDefaultOffice { get; set; }
        public string Title { get; set; }
        public IEnumerable<OfficialNumber> OfficialNumbers { get; set; }
        public decimal? BudgetAmount { get; set; }
        public decimal? RevisedBudgetAmount { get; set; }
        public DateTime? BudgetStartDate { get; set; }
        public DateTime? BudgetEndDate { get; set; }
        public string FamilyId { get; set; }
        public TableCode TypeOfMark { get; set; }

        public Case Build()
        {
            var returnCase = new Case(
                                      Irn ?? Fixture.String("Irn"),
                                      Country ?? new CountryBuilder {Id = CountryCode, Adjective = CountryAdjective}.Build(),
                                      CaseType ?? new CaseTypeBuilder().Build(),
                                      PropertyType ?? new PropertyTypeBuilder().Build(),
                                      Property)
            {
                Office = Office ?? (HasNoDefaultOffice ? null : new OfficeBuilder().Build()),
                CaseStatus = Status ?? (HasNoDefaultStatus ? null : new StatusBuilder().Build()),
                Title = Title ?? Fixture.String("Title"),

                SubType = SubType ?? new SubTypeBuilder().Build()
            };
            returnCase.PropertyTypeId = returnCase.PropertyType.Code;

            if (OfficialNumbers != null)
            {
                returnCase.OfficialNumbers.AddRange(OfficialNumbers);
            }

            if (IsPrimeCase)
            {
                returnCase.CaseListMemberships.Add(
                                                   new CaseListMemberBuilder
                                                   {
                                                       CaseId = returnCase.Id,
                                                       IsPrimeCase = true
                                                   }.Build());
            }
            returnCase.BudgetAmount = BudgetAmount;
            returnCase.BudgetRevisedAmt = RevisedBudgetAmount;
            returnCase.BudgetStartDate = BudgetStartDate;
            returnCase.BudgetEndDate = BudgetEndDate;
            returnCase.FamilyId = FamilyId;
            returnCase.TypeOfMark = TypeOfMark;
            returnCase.TypeOfMarkId = TypeOfMark?.Id; 
            return returnCase;
        }
        
        public Case BuildWithId(int id)
        {
            var subType = SubType ?? new SubTypeBuilder().Build();
            var category = new CaseCategoryBuilder().Build();
            var returnCase = new Case(
                                      id,
                                      Irn ?? Fixture.String("Irn"),
                                      Country ?? new CountryBuilder {Id = CountryCode, Adjective = CountryAdjective}.Build(),
                                      CaseType ?? new CaseTypeBuilder().Build(),
                                      PropertyType ?? new PropertyTypeBuilder().Build(),
                                      Property)
            {
                Office = Office ?? new OfficeBuilder().Build(),
                CaseStatus = Status ?? (HasNoDefaultStatus ? null : new StatusBuilder().Build()),
                Title = Title ?? Fixture.String("Title"),
                SubType = subType,
                SubTypeId = subType.Code,
                Category = category,
                CategoryId = category.CaseCategoryId
            };
            returnCase.PropertyTypeId = returnCase.PropertyType.Code;

            if (OfficialNumbers != null)
            {
                returnCase.OfficialNumbers.AddRange(OfficialNumbers);
            }

            if (IsPrimeCase)
            {
                returnCase.CaseListMemberships.Add(
                                                   new CaseListMemberBuilder
                                                   {
                                                       CaseId = returnCase.Id,
                                                       IsPrimeCase = true
                                                   }.Build());
            }

            return returnCase;
        }
        public static CaseBuilder AsPrimeCase()
        {
            return new CaseBuilder {IsPrimeCase = true};
        }
    }

    public static class CaseBuilderEx
    {
        public static CaseBuilder WithCountry(this CaseBuilder builder, Country country)
        {
            builder.Country = country;
            return builder;
        }
    }
}