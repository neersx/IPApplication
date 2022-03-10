using System.Linq;
using Inprotech.Tests.Web.Builders.Model.Rules;
using InprotechKaizen.Model.Rules;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration.Rules
{
    public class ReminderRuleFacts
    {
        public class InheritFromMethod
        {
            [Fact]
            public void CopiesPropertiesAndSetsInheritedFlag()
            {
                var subject = new ReminderRule(new ValidEventBuilder().Build(), Fixture.Short());
                var from = new ReminderRule(new ValidEventBuilder().Build(), Fixture.Short());

                DataFiller.Fill(from);
                from.IsInherited = false;

                subject.InheritRuleFrom(from);

                Assert.NotEqual(from.CriteriaId, subject.CriteriaId);
                Assert.NotEqual(from.EventId, subject.EventId);
                Assert.NotEqual(from.Sequence, subject.Sequence);
                Assert.NotEqual(from.Inherited, subject.Inherited);
                Assert.NotEqual(from.Message1TId, subject.Message1TId);
                Assert.NotEqual(from.Message2TId, subject.Message2TId);
                Assert.True(subject.IsInherited);

                Assert.Equal(subject.PeriodType, from.PeriodType);
                Assert.Equal(subject.LeadTime, from.LeadTime);
                Assert.Equal(subject.Frequency, from.Frequency);
                Assert.Equal(subject.StopTime, from.StopTime);
                Assert.Equal(subject.UpdateEvent, from.UpdateEvent);
                Assert.Equal(subject.LetterNo, from.LetterNo);
                Assert.Equal(subject.CheckOverride, from.CheckOverride);
                Assert.Equal(subject.MaxLetters, from.MaxLetters);
                Assert.Equal(subject.LetterFeeId, from.LetterFeeId);
                Assert.Equal(subject.PayFeeCode, from.PayFeeCode);
                Assert.Equal(subject.EmployeeFlag, from.EmployeeFlag);
                Assert.Equal(subject.SignatoryFlag, from.SignatoryFlag);
                Assert.Equal(subject.InstructorFlag, from.InstructorFlag);
                Assert.Equal(subject.CriticalFlag, from.CriticalFlag);
                Assert.Equal(subject.RemindEmployeeId, from.RemindEmployeeId);
                Assert.Equal(subject.UseMessage1, from.UseMessage1);
                Assert.Equal(subject.Message1, from.Message1);
                Assert.Equal(subject.Message2, from.Message2);
                Assert.Equal(subject.NameType, from.NameType);
                Assert.Equal(subject.SendElectronically, from.SendElectronically);
                Assert.Equal(subject.EmailSubject, from.EmailSubject);
                Assert.Equal(subject.EstimateFlag, from.EstimateFlag);
                Assert.Equal(subject.FreqPeriodType, from.FreqPeriodType);
                Assert.Equal(subject.StopTimePeriodType, from.StopTimePeriodType);
                Assert.Equal(subject.DirectPayFlag, from.DirectPayFlag);
                Assert.Equal(subject.RelationshipId, from.RelationshipId);
                Assert.Equal(subject.ExtendedNameType, from.ExtendedNameType);
            }
        }

        public class TypeIdentifiers
        {
            [Fact]
            public void IdentifiesReminderRows()
            {
                var r = new ReminderRuleBuilder().Build();
                var d = new ReminderRuleBuilder().AsDocumentRule().Build();
                var list = new[] {r, d};
                var result = list.WhereReminder().ToArray();
                Assert.Equal(r, result.Single());
            }
        }

        public class NameTypesProperty
        {
            [Fact]
            public void ReturnsListOfNameTypes()
            {
                var r = new ReminderRuleBuilder().Build();
                r.NameTypeId = "A";
                r.ExtendedNameType = "B; C ; D; E";
                Assert.Equal(r.NameTypeId, r.NameTypes.Single());

                r.NameTypeId = null;
                Assert.Equal(4, r.NameTypes.Distinct().Count());
                Assert.Contains("B", r.NameTypes);
                Assert.Contains("C", r.NameTypes);
                Assert.Contains("D", r.NameTypes);
                Assert.Contains("E", r.NameTypes);
            }

            [Fact]
            public void SetsNameTypesIntoAppropriateFields()
            {
                var r = new ReminderRuleBuilder().Build();
                r.NameTypes = new[] {"A"};
                Assert.Equal("A", r.NameTypeId);
                Assert.Null(r.ExtendedNameType);

                r.NameTypes = new[] {"B", "C", "D", "E"};
                Assert.Null(r.NameTypeId);
                Assert.Equal("B;C;D;E", r.ExtendedNameType);

                r.NameTypes = null;
                Assert.Null(r.NameTypeId);
                Assert.Null(r.ExtendedNameType);
            }
        }

        public class LeadTimeToDaysMethod
        {
            [Theory]
            [InlineData(1, "D", 1)]
            [InlineData(1982, "D", 1982)]
            [InlineData(2, "M", 60)]
            [InlineData(3, "W", 21)]
            [InlineData(4, "Y", 1460)]
            public void ConvertsLeadTimeToDays(int period, string periodType, int expectedResult)
            {
                var r = new ReminderRule {LeadTime = (short) period, PeriodType = periodType};
                Assert.Equal(expectedResult, r.LeadTimeToDays());
            }
        }
    }
}