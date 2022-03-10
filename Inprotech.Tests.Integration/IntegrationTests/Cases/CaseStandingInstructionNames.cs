using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Cases
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class CaseStandingInstructionNames
    {
        [Test]
        public void EnsureTheViewDoesNotReturnExpiredCaseNameData()
        {
            var dbData = DbSetup.Do(setup =>
            {
                var instructionTypeBuilder = new InstructionTypeBuilder(setup.DbContext);
                var instructionType = instructionTypeBuilder.Create();

                var @case = new CaseBuilder(setup.DbContext).Create("Case 1");

                var name = new NameBuilder(setup.DbContext).Create();
                var caseName = new CaseName(
                                            @case,
                                            instructionType.NameType,
                                            name,
                                            (short) (@case.CaseNames.Max(_ => _.Sequence) + 1)
                                           )
                {
                    ExpiryDate = DateTime.Now.AddDays(-1)
                };
                @case.CaseNames.Add(caseName);
                setup.DbContext.SaveChanges();
                return setup.DbContext.Set<CaseStandingInstructionsNamesView>().Where(_ => _.CaseId == @case.Id && _.NameTypeCode == caseName.NameType.NameTypeCode && _.NameId == caseName.Name.Id).ToList();
            });

            Assert.AreEqual(0, dbData.Count, "Expired case names should not be returned from the view");
        }

        [Test]
        public void EnsureTheViewReturnsData()
        {
            var dbData = DbSetup.Do(setup =>
            {
                var instructionTypeBuilder = new InstructionTypeBuilder(setup.DbContext);
                var instructionType = instructionTypeBuilder.Create();
                setup.DbContext.SaveChanges();
                return setup.DbContext.Set<CaseStandingInstructionsNamesView>().Where(_ => _.NameTypeCode == instructionType.NameType.NameTypeCode).ToList();
            });

            Assert.AreNotEqual(0, dbData.Count, "Saved Instruction types need to be returned.");
        }

        [Test]
        public void EnsureToGetCaseOfficeOrgName()
        {
            var dbData = DbSetup.Do(setup =>
            {
                var instructionTypeBuilder = new InstructionTypeBuilder(setup.DbContext);
                instructionTypeBuilder.Create();

                var @case = new CaseBuilder(setup.DbContext).Create("Case 2");

                var name = new NameBuilder(setup.DbContext).Create();
                @case.Office = new Office
                {
                    Id = Fixture.Integer(),
                    Name = Fixture.String(5),
                    Organisation = name
                };
                setup.DbContext.SaveChanges();
                return setup.DbContext.Set<CaseStandingInstructionsNamesView>().Where(_ => _.CaseId == @case.Id && _.NameId == @case.Office.Organisation.Id).ToList();
            });

            Assert.AreNotEqual(0, dbData.Count, "Case Office Organization Name needs be return from View if it is not null");
        }

        [Test]
        public void EnsureToGetReferenceNameTypes()
        {
            var dbData = DbSetup.Do(setup =>
            {
                var nameTypeBuilder = new NameTypeBuilder(setup.DbContext);
                var restrictedNameType = nameTypeBuilder.Create();
                restrictedNameType.IsNameRestricted = 1;

                var instructionTypeBuilder = new InstructionTypeBuilder(setup.DbContext);
                var instructionType = instructionTypeBuilder.Create();

                instructionType.RestrictedByType = restrictedNameType;

                var @case = new CaseBuilder(setup.DbContext).Create("Case 3");

                var name = new NameBuilder(setup.DbContext).Create();

                var caseName = new CaseName(
                                            @case,
                                            instructionType.RestrictedByType,
                                            name,
                                            (short) (@case.CaseNames.Max(_ => _.Sequence) + 1)
                                           );
                @case.CaseNames.Add(caseName);

                setup.DbContext.SaveChanges();
                return setup.DbContext.Set<CaseStandingInstructionsNamesView>().Where(_ => _.CaseId == @case.Id && _.NameTypeCode == caseName.NameType.NameTypeCode).ToList();
            });

            Assert.AreNotEqual(0, dbData.Count, "ReferenceType needs be return from View, if ReferenceType is set");
        }
    }
}