using Inprotech.Web.Configuration.SanityCheck;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.SanityCheck
{
    public class SanityCheckNameViewModelFacts
    {
        [Fact]
        public void ConvertsBasicDetails()
        {
            var model = new SanityCheckNameViewModel
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
        public void ConvertNameCharacteristics()
        {
            var model = new SanityCheckNameViewModel
            {
                RuleOverview =
                {
                    DisplayMessage = "Arthur",
                    RuleDescription = "A"
                },
                NameCharacteristics = new SanityCheckNameViewModel.NameCharacteristicsModel
                {
                    Jurisdiction = "AUS",
                    IsLocal = true,
                    Name = 10,
                    IsSupplierOnly = true
                }
            };

            var record = model.ToDataValidation();
            Assert.Equal(model.RuleOverview.DisplayMessage, record.DisplayMessage);
            Assert.Equal(model.RuleOverview.RuleDescription, record.RuleDescription);

            Assert.Equal(model.NameCharacteristics.Jurisdiction, record.CountryCode);
            Assert.Equal(model.NameCharacteristics.IsLocal, record.LocalclientFlag);
            Assert.Equal(model.NameCharacteristics.Name, record.NameId);
            Assert.Equal(model.NameCharacteristics.IsSupplierOnly, record.SupplierFlag);
        }

        [Theory]
        [InlineData(false, false, false, false, null)]
        [InlineData(true, false, false, false, 0)]
        [InlineData(false, true, false, false, 1)]
        [InlineData(false, false, true, false, 4)]
        [InlineData(false, false, false, true, 2)]
        [InlineData(true, false, true, false, 4)]
        [InlineData(false, true, true, false, 5)]
        [InlineData(false, true, false, true, 3)]
        public void SetCorrectUsedAs(bool isOrganisation, bool isIndividual, bool isClientOnly, bool isStaff, int? usedAs)
        {
            var nameCharacteristics = new SanityCheckNameViewModel.NameCharacteristicsModel
            {
                EntityType = new SanityCheckNameViewModel.EntityTypeModel
                {
                    IsOrganisation = isOrganisation,
                    IsIndividual = isIndividual,
                    IsClientOnly = isClientOnly,
                    IsStaff = isStaff
                }
            };

            Assert.Equal((short?)usedAs, nameCharacteristics.EntityType.GetUsedAsFlag());
        }

        [Fact]
        public void ConvertStandingInstructions()
        {
            var model = new SanityCheckNameViewModel
            {
                RuleOverview =
                {
                    DisplayMessage = "Arthur",
                    RuleDescription = "A"
                },
                StandingInstruction = new StandingInstructionModel
                {
                    InstructionType = "A",
                    Characteristics = 100
                }
            };

            var record = model.ToDataValidation();
            Assert.Equal(model.StandingInstruction.InstructionType, record.InstructionType);
            Assert.Equal(model.StandingInstruction.Characteristics, record.FlagNumber);
        }

        [Fact]
        public void ConvertOther()
        {
            var model = new SanityCheckNameViewModel
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

        [Theory]
        [InlineData(null, null, false, false, true)]
        [InlineData(80, null, false, false, true)]
        [InlineData(null, 60, false, false, true)]
        [InlineData(null, null, true, false, true)]
        [InlineData(null, null, false, true, true)]
        [InlineData(10, 100, false, false, false)]
        [InlineData(null, null, true, true, false)]
        public void CheckValidityOfNameCharacteristics(int? name, int? nameGroup, bool isOrganisation, bool IsIndividual, bool isValid)
        {
            var model = new SanityCheckNameViewModel
            {
                RuleOverview = new RuleOverviewModel
                {
                    DisplayMessage = "Arthur",
                    RuleDescription = "A"
                },
                NameCharacteristics = new SanityCheckNameViewModel.NameCharacteristicsModel
                {
                    Name = name,
                    NameGroup = (short?)nameGroup,
                    EntityType = new SanityCheckNameViewModel.EntityTypeModel
                    {
                        IsOrganisation = isOrganisation,
                        IsIndividual = IsIndividual
                    }
                }
            };

            Assert.Equal(isValid, model.IsValid());
        }

        [Theory]
        [InlineData(true, true, false, false, false)]
        [InlineData(true, false, false, true, false)]
        [InlineData(false, false, true, true, false)]
        [InlineData(false, false, true, false, false)]
        [InlineData(false, false, false, true, false)]
        [InlineData(true, true, true, true, false)]
        [InlineData(false, false, false, false, true)]
        [InlineData(true, false, false, false, true)]
        [InlineData(false, true, false, false, true)]
        [InlineData(false, true, false, true, true)]
        [InlineData(true, false, true, false, true)]
        [InlineData(false, true, true, false, true)]
        public void CheckValidityOfEntityType(bool isOrganisation, bool isIndividual, bool isClientOnly, bool isStaff, bool isValid)
        {
            var nameCharacteristics = new SanityCheckNameViewModel.NameCharacteristicsModel
            {
                EntityType = new SanityCheckNameViewModel.EntityTypeModel
                {
                    IsOrganisation = isOrganisation,
                    IsIndividual = isIndividual,
                    IsClientOnly = isClientOnly,
                    IsStaff = isStaff
                }
            };

            Assert.Equal(isValid, nameCharacteristics.EntityType.IsValid());
        }
    }
}