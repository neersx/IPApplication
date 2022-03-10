using System.ComponentModel.DataAnnotations;
using InprotechKaizen.Model;
using InprotechKaizen.Model.DataValidation;

namespace Inprotech.Web.Configuration.SanityCheck
{
    public class SanityCheckNameViewUpdateModel : SanityCheckNameViewModel
    {
        public int ValidationId { get; set; }
    }

    public class SanityCheckNameViewModel : BaseSanityCheckViewModel
    {
        public SanityCheckNameViewModel()
        {
            NameCharacteristics = new NameCharacteristicsModel();
        }

        public NameCharacteristicsModel NameCharacteristics { get; set; }

        public bool IsValid()
        {
            return RuleOverview.IsValid() && NameCharacteristics.IsValid() && StandingInstruction.IsValid();
        }

        public DataValidation ToDataValidation(DataValidation dataValidation = null)
        {
            dataValidation ??= new DataValidation();

            dataValidation.DisplayMessage = RuleOverview.DisplayMessage;
            dataValidation.RuleDescription = RuleOverview.RuleDescription;
            dataValidation.Notes = RuleOverview.Notes;
            dataValidation.DeferredFlag = RuleOverview.Deferred.GetValueOrDefault();
            dataValidation.InUseFlag = RuleOverview.InUse.GetValueOrDefault();
            dataValidation.IsWarning = RuleOverview.InformationOnly.GetValueOrDefault();
            dataValidation.ItemId = RuleOverview.SanityCheckSql;
            dataValidation.CanOverrideRoleId = RuleOverview.MayBypassError;
            dataValidation.ItemId = RuleOverview.SanityCheckSql;

            dataValidation.NameId = NameCharacteristics.Name;
            dataValidation.FamilyNo = NameCharacteristics.NameGroup;
            dataValidation.CountryCode = NameCharacteristics.Jurisdiction;
            dataValidation.Category = NameCharacteristics.Category;
            dataValidation.LocalclientFlag = NameCharacteristics.IsLocal;
            dataValidation.UsedasFlag = NameCharacteristics.EntityType.GetUsedAsFlag();
            dataValidation.SupplierFlag = NameCharacteristics.IsSupplierOnly;

            dataValidation.InstructionType = StandingInstruction.InstructionType;
            dataValidation.FlagNumber = StandingInstruction.Characteristics;

            dataValidation.ColumnName = Other.TableCode;

            return dataValidation;
        }

        public class NameCharacteristicsModel
        {
            public NameCharacteristicsModel()
            {
                EntityType = new EntityTypeModel();
            }

            public int? Name { get; set; }
            public short? NameGroup { get; set; }

            [MaxLength(3)]
            public string Jurisdiction { get; set; }

            public short? Category { get; set; }

            public bool? IsLocal { get; set; }

            public EntityTypeModel EntityType { get; set; }

            public bool IsSupplierOnly { get; set; }

            public bool IsValid()
            {
                if (Name.HasValue && NameGroup.HasValue || !EntityType.IsValid())
                {
                    return false;
                }

                return true;
            }
        }

        public class EntityTypeModel
        {
            public bool IsOrganisation { get; set; }
            public bool IsIndividual { get; set; }
            public bool IsClientOnly { get; set; }
            public bool IsStaff { get; set; }

            public short? GetUsedAsFlag()
            {
                short? result = null;

                if (IsOrganisation)
                {
                    result = NameUsedAs.Organisation;
                }

                if (IsIndividual)
                {
                    result = (short)((result ?? 0) | NameUsedAs.Individual);
                }

                if (IsClientOnly)
                {
                    result = (short)((result ?? 0) | NameUsedAs.Client);
                }

                if (IsStaff)
                {
                    result = (short)((result ?? 0) | NameUsedAs.StaffMember);
                }

                return result;
            }

            public bool IsValid()
            {
                if (IsOrganisation && IsIndividual || IsOrganisation && IsStaff || IsClientOnly && IsStaff || (IsClientOnly || IsStaff) && !IsOrganisation && !IsIndividual)
                {
                    return false;
                }

                return true;
            }
                    }
                    }
}