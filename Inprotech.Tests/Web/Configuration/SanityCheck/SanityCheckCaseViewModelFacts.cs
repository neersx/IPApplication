using Inprotech.Web.Configuration.SanityCheck;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.SanityCheck
{
    public class SanityCheckCaseViewModelFacts
    {
        [Theory]
        [InlineData(false, true, true, 3)]
        [InlineData(true, true, true, 3)]
        [InlineData(true, true, false, 0)]
        [InlineData(true, false, false, 0)]
        [InlineData(true, false, true, 0)]
        [InlineData(false, true, false, 1)]
        [InlineData(false, false, true, 2)]
        public void GetsCorrectStatusFlag(bool includeDead, bool includePending, bool includeRegistered, int outcome)
        {
            var data = new SanityCheckCaseViewModel
            {
                CaseCharacteristics = new CaseCharacteristicsModel
                {
                    StatusIncludeDead = includeDead,
                    StatusIncludePending = includePending,
                    StatusIncludeRegistered = includeRegistered
                }
            };

            Assert.Equal((short?) outcome, data.CaseCharacteristics.GetStatusFlag());
        }

        [Fact]
        public void ConvertsBasicDetails()
        {
            var model = new SanityCheckCaseViewModel
            {
                RuleOverview =
                {
                    DisplayMessage = "Arthur",
                    RuleDescription = "A",
                    Notes = "La la land",
                    Deferred = true,
                    InUse = true,
                    InformationOnly = true,
                    SanityCheckSql = 1,
                    MayBypassError = 111
                }
            };

            var record = model.ToDataValidation();
            Assert.Equal(model.RuleOverview.DisplayMessage, record.DisplayMessage);
            Assert.Equal(model.RuleOverview.RuleDescription, record.RuleDescription);
            Assert.Equal(model.RuleOverview.Notes, record.Notes);
            Assert.Equal(model.RuleOverview.Deferred, record.DeferredFlag);
            Assert.Equal(model.RuleOverview.InUse, record.InUseFlag);
            Assert.Equal(model.RuleOverview.InformationOnly, record.IsWarning);
            Assert.Equal(model.RuleOverview.SanityCheckSql, record.ItemId);
            Assert.Equal(model.RuleOverview.MayBypassError, record.CanOverrideRoleId);
        }

        [Fact]
        public void ConvertCaseCharacteristics()
        {
            var model = new SanityCheckCaseViewModel
            {
                RuleOverview =
                {
                    DisplayMessage = "Arthur",
                    RuleDescription = "A"
                },
                CaseCharacteristics = new CaseCharacteristicsModel
                {
                    Office = 1,
                    CaseType = "A",
                    Jurisdiction = "AUS",
                    PropertyType = "P",
                    CaseCategory = "C",
                    SubType = "S",
                    Basis = "B",
                    ApplyTo = true,
                    StatusIncludeDead = true,
                    StatusIncludePending = false,
                    StatusIncludeRegistered = false,

                    CaseTypeExclude = false,
                    JurisdictionExclude = true,
                    PropertyTypeExclude = false,
                    CaseCategoryExclude = false,
                    SubTypeExclude = true,
                    BasisExclude = false
                }
            };

            var record = model.ToDataValidation();
            Assert.Equal(model.RuleOverview.DisplayMessage, record.DisplayMessage);
            Assert.Equal(model.RuleOverview.RuleDescription, record.RuleDescription);

            Assert.Equal(model.CaseCharacteristics.Office, record.OfficeId);
            Assert.Equal(model.CaseCharacteristics.CaseType, record.CaseType);
            Assert.Equal(model.CaseCharacteristics.Jurisdiction, record.CountryCode);
            Assert.Equal(model.CaseCharacteristics.PropertyType, record.PropertyType);
            Assert.Equal(model.CaseCharacteristics.CaseCategory, record.CaseCategory);
            Assert.Equal(model.CaseCharacteristics.SubType, record.SubType);
            Assert.Equal(model.CaseCharacteristics.Basis, record.Basis);
            Assert.Equal(model.CaseCharacteristics.ApplyTo, record.LocalclientFlag);
            Assert.Equal((short?) 0, record.StatusFlag);
            Assert.Equal(model.CaseCharacteristics.CaseTypeExclude, record.NotCaseType);
            Assert.Equal(model.CaseCharacteristics.JurisdictionExclude, record.NotCountryCode);
            Assert.Equal(model.CaseCharacteristics.PropertyTypeExclude, record.NotPropertyType);
            Assert.Equal(model.CaseCharacteristics.CaseCategoryExclude, record.NotCaseCategory);
            Assert.Equal(model.CaseCharacteristics.SubTypeExclude, record.NotSubtype);
            Assert.Equal(model.CaseCharacteristics.BasisExclude, record.NotBasis);
        }

        [Fact]
        public void ConvertCaseName()
        {
            var model = new SanityCheckCaseViewModel
            {
                RuleOverview =
                {
                    DisplayMessage = "Arthur",
                    RuleDescription = "A"
                },
                CaseName = new CaseNameModel
                {
                    NameGroup = 1,
                    Name = 2,
                    NameType = "A"
                }
            };

            var record = model.ToDataValidation();
            Assert.Equal(model.CaseName.NameGroup, record.FamilyNo);
            Assert.Equal(model.CaseName.Name, record.NameId);
            Assert.Equal(model.CaseName.NameType, record.NameType);
        }

        [Fact]
        public void ConvertStandingInstructions()
        {
            var model = new SanityCheckCaseViewModel
            {
                RuleOverview =
                {
                    DisplayMessage = "Arthur",
                    RuleDescription = "A"
                },
                StandingInstruction = new StandingInstructionModel()
                {
                    InstructionType = "A",
                    Characteristics = 100
                }
            };

            var record = model.ToDataValidation();
            Assert.Equal(model.StandingInstruction.InstructionType, record.InstructionType);
            Assert.Equal(model.StandingInstruction.Characteristics, record.FlagNumber);
        }

        [Theory]
        [InlineData(null, null, null, null)]
        [InlineData(100, true, null, 2)]
        [InlineData(100, null, true, 1)]
        [InlineData(100, true, true, 3)]
        public void ConvertEvent(int? eventNo, bool? includeDue, bool? includeOccurred, int? eventDateFlag)
        {
            var model = new SanityCheckCaseViewModel
            {
                RuleOverview =
                {
                    DisplayMessage = "Arthur",
                    RuleDescription = "A"
                },
                Event = new EventModel
                {
                    EventNo = eventNo,
                    IncludeDue = includeDue,
                    IncludeOccurred = includeOccurred
                }
            };

            var record = model.ToDataValidation();
            Assert.Equal(model.Event.EventNo, record.EventNo);
            Assert.Equal(eventDateFlag, record.Eventdateflag);
        }

        [Theory]
        [InlineData(true, false, new short[] {2, 3})]
        [InlineData(false, true, new short[] {1, 3})]
        [InlineData(false, false, new short[0])]
        [InlineData(true, true, new short[] {1, 2, 3})]
        public void SetCorrectEventStatus(bool due, bool occcured, short[] flag)
        {
            var filter = new SanityCheckCaseViewModel
            {
                Event = new EventModel
                {
                    EventNo = 10,
                    IncludeDue = due,
                    IncludeOccurred = occcured
                }
            };

            Assert.Equal(flag, filter.Event.GetEventDateFlags());
        }

        [Theory]
        [InlineData(true, false, false, new short[] {0})]
        [InlineData(true, true, false, new short[] {0, 1, 3})]
        [InlineData(true, true, true, new short[] {0, 1, 2, 3})]
        [InlineData(false, false, false, new short[0])]
        [InlineData(false, true, false, new short[] {1, 3})]
        [InlineData(false, false, true, new short[] {2, 3})]
        [InlineData(false, true, true, new short[] {1, 2, 3})]
        public void SetCorrectStatus(bool dead, bool pending, bool registered, short[] status)
        {
            var filter = new SanityCheckCaseViewModel
            {
                CaseCharacteristics = new CaseCharacteristicsModel
                {
                    StatusIncludePending = pending,
                    StatusIncludeDead = dead,
                    StatusIncludeRegistered = registered
                }
            };

            Assert.Equal(status, filter.CaseCharacteristics.GetStatusFlags());
        }

        [Fact]
        public void ConvertOther()
        {
            var model = new SanityCheckCaseViewModel
            {
                RuleOverview =
                {
                    DisplayMessage = "Arthur",
                    RuleDescription = "A"
                },
                Other = new OtherModel
                {
                    TableCode = 100
                }
            };

            var record = model.ToDataValidation();
            Assert.Equal(model.Other.TableCode, record.ColumnName);
        }
    }

    public class RuleOverviewModelFacts
    {
        [Theory]
        [InlineData(null, null, null, null, false)]
        [InlineData("A", null, null, null, false)]
        [InlineData(null, "A", true, 10, false)]
        [InlineData("A", "A", null, null, true)]
        [InlineData("A", "A", true, null, false)]
        [InlineData("A", "A", false, null, true)]
        [InlineData("A", "A", true, 10, true)]
        public void ChecksValidity(string ruleDescription, string displayMessage, bool? deferred, int? sanityCheckSql, bool result)
        {
            var model = new RuleOverviewModel()
            {
                RuleDescription = ruleDescription,
                DisplayMessage = displayMessage,
                Deferred = deferred,
                SanityCheckSql = sanityCheckSql,
                InformationOnly = true,
                InUse = false,
                MayBypassError = null,
                Notes = "Something nice"
            };

            Assert.Equal(result, model.IsValid());
        }
    }

    public class CaseNameModelFacts
    {
        [Theory]
        [InlineData(null, null, true)]
        [InlineData(1, null, true)]
        [InlineData(null, 1, true)]
        [InlineData(1, 10, false)]
        public void ChecksValidity(int? name, int? nameGroup, bool result)
        {
            var model = new CaseNameModel
            {
                Name = name,
                NameGroup = (short?)nameGroup,
                NameType = "T"
            };

            Assert.Equal(result, model.IsValid());
        }
    }

    public class StandingInstructionModelFacts
    {
        [Theory]
        [InlineData(null, null, true)]
        [InlineData("A", null, false)]
        [InlineData("A", 1, true)]
        public void ChecksValidity(string instructionType, int? characteristics, bool result)
        {
            var model = new StandingInstructionModel
            {
                InstructionType = instructionType,
                Characteristics = (short?)characteristics
            };

            Assert.Equal(result, model.IsValid());
        }
    }
}