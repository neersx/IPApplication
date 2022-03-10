using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using Name = Inprotech.Web.Picklists.Name;

namespace Inprotech.Web.Configuration.Core
{
    public class NameTypeSaveDetails
    {
        public int Id { get; set; }

        public string NameTypeCode { get; set; }

        public string Name { get; set; }

        public short? MaximumAllowed { get; set; }

        public string MinAllowedForCase { get; set; }

        public bool IsMandatory { get; set; }

        public DisplayNameCode DisplayNameCode { get; set; }

        public bool IsAttentionDisplayed { get; set; }

        public bool IsAddressDisplayed { get; set; }

        public bool IsReferenceNumberDisplayed { get; set; }

        public bool IsAssignDateDisplayed { get; set; }

        public bool IsDateCommencedDisplayed { get; set; }

        public bool IsDateCeasedDisplayed { get; set; }

        public bool IsBillPercentDisplayed { get; set; }

        public bool IsInheritedDisplayed { get; set; }

        public bool IsStandardNameDisplayed { get; set; }

        public bool IsNameVariantDisplayed { get; set; }

        public bool IsRemarksDisplayed { get; set; }

        public bool IsCorrespondenceDisplayed { get; set; }

        public bool IsEnforceNameRestriction { get; set; }

        public bool IsNameStreetSaved { get; set; }

        public bool IsClassified { get; set; }

        public bool IsNationalityDisplayed { get; set; }

        public bool AllowStaffNames { get; set; }

        public bool AllowOrganisationNames { get; set; }

        public bool AllowIndividualNames { get; set; }

        public bool AllowClientNames { get; set; }

        public bool AllowCrmNames { get; set; }

        public bool AllowSuppliers { get; set; }

        public bool AddNameTypeClassification { get; set; }

        public NameTypeModel PathNameTypePickList { get; set; }

        public NameRelationshipModel PathNameRelation { get; set; }

        public NameTypeModel FutureNameTypePickList { get; set; }

        public NameTypeModel OldNameTypePickList { get; set; }

        public ICollection<NameTypeGroup> NameTypeGroup { get; set; }

        public bool UpdateFromParentNameType { get; set; }

        public bool UseHomeNameRelationship { get; set; }

        public bool UseNameType { get; set; }

        public int? ChangeEventNo { get; set; }

        public Event ChangeEvent { get; set; }

        public Name DefaultName { get; set; }

        public EthicalWallOption EthicalWallOption { get; set; }

        public short PriorityOrder { get; set; }
    }

    public enum DisplayNameCode
    {
        Start = 1,
        End = 2,
        None
    }

    public enum EthicalWallOption
    {
        AllowAccess = 1,
        DenyAccess = 2,
        NotApplicable = 0
    }

    public class NameTypeTranslator
    {
        readonly IDbContext _dbContext;

        public NameTypeTranslator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public NameType AddNameType(NameTypeSaveDetails details)
        {
            var nameType = new NameType(details.NameTypeCode, details.Name);
            return SetNameTypeFromDetails(details, nameType);
        }

        public NameType SetNameTypeFromDetails(NameTypeSaveDetails details, NameType nameType)
        {
            nameType.NameTypeCode = details.NameTypeCode;
            nameType.Name = details.Name;
            nameType.ShowNameCode = Convert.ToDecimal(details.DisplayNameCode);
            nameType.MaximumAllowed = details.MaximumAllowed;
            nameType.MandatoryFlag = details.MinAllowedForCase == "1" ? 1m : 0m;
            nameType.IsNameRestricted = details.IsEnforceNameRestriction.ToDecimal();
            nameType.KeepStreetFlag = details.IsNameStreetSaved.ToDecimal();
            nameType.ColumnFlag = Convert.ToInt16((Convert.ToInt16(details.IsAttentionDisplayed) * KnownNameTypeColumnFlags.DisplayAttention)
                                    | (Convert.ToInt16(details.IsAddressDisplayed) * KnownNameTypeColumnFlags.DisplayAddress)
                                    | (Convert.ToInt16(details.IsReferenceNumberDisplayed) * KnownNameTypeColumnFlags.DisplayReferenceNumber)
                                    | (Convert.ToInt16(details.IsAssignDateDisplayed) * KnownNameTypeColumnFlags.DisplayAssignDate)
                                    | (Convert.ToInt16(details.IsDateCommencedDisplayed) * KnownNameTypeColumnFlags.DisplayDateCommenced)
                                    | (Convert.ToInt16(details.IsDateCeasedDisplayed) * KnownNameTypeColumnFlags.DisplayDateCeased)
                                    | (Convert.ToInt16(details.IsBillPercentDisplayed) * KnownNameTypeColumnFlags.DisplayBillPercentage)
                                    | (Convert.ToInt16(details.IsInheritedDisplayed) * KnownNameTypeColumnFlags.DisplayInherited)
                                    | (Convert.ToInt16(details.IsStandardNameDisplayed) * KnownNameTypeColumnFlags.DisplayStandardName)
                                    | (Convert.ToInt16(details.IsNameVariantDisplayed) * KnownNameTypeColumnFlags.DisplayNameVariant)
                                    | (Convert.ToInt16(details.IsRemarksDisplayed) * KnownNameTypeColumnFlags.DisplayRemarks)
                                    | (Convert.ToInt16(details.IsCorrespondenceDisplayed) * KnownNameTypeColumnFlags.DisplayCorrespondence));
            nameType.PickListFlags =
                Convert.ToInt16((Convert.ToInt16(details.IsClassified) * KnownNameTypeAllowedFlags.SameNameType)
                                | (Convert.ToInt16(details.AllowStaffNames) * KnownNameTypeAllowedFlags.StaffNames)
                                |
                                (Convert.ToInt16(details.AllowOrganisationNames) * KnownNameTypeAllowedFlags.Organisation)
                                | (Convert.ToInt16(details.AllowIndividualNames) * KnownNameTypeAllowedFlags.Individual)
                                | (Convert.ToInt16(details.AllowClientNames) * KnownNameTypeAllowedFlags.Client)
                                | (Convert.ToInt16(details.AllowCrmNames) * KnownNameTypeAllowedFlags.CrmNameType)
                                | (Convert.ToInt16(details.AllowSuppliers) * KnownNameTypeAllowedFlags.Supplier));

            if (details.IsNameStreetSaved && !details.IsAddressDisplayed)
            {
                nameType.ColumnFlag = Convert.ToInt16(nameType.ColumnFlag | KnownNameTypeColumnFlags.DisplayAddress);
            }
            nameType.PathNameType = details.PathNameTypePickList?.Code;
            nameType.PathRelationship = details.PathNameRelation?.Key;
            nameType.FutureNameType = details.FutureNameTypePickList?.Code;
            nameType.OldNameType = details.OldNameTypePickList?.Code;
            nameType.UseHomeNameRelationship = details.UseHomeNameRelationship;
            nameType.UpdateFromParent = details.UpdateFromParentNameType;
            nameType.HierarchyFlag = details.UseNameType.ToDecimal();
            nameType.ChangeEventNo = details.ChangeEvent?.Key;
            nameType.DefaultNameId = details.DefaultName?.Key;
            nameType.EthicalWall = Convert.ToByte(details.EthicalWallOption);
            nameType.NationalityFlag = details.IsNationalityDisplayed;
            return nameType;
        }

        public NameTypeSaveDetails SetNameTypeSaveDetailsFromNameType(NameType nameType)
        {
            var saveDetails = new NameTypeSaveDetails
            {
                Id = nameType.Id,
                NameTypeCode = nameType.NameTypeCode,
                Name = nameType.Name,
                MaximumAllowed = nameType.MaximumAllowed,
                MinAllowedForCase = nameType.IsMandatory ? "1" : "0",
                IsMandatory = nameType.IsMandatory,
                AllowClientNames = nameType.AllowClientNames,
                AllowIndividualNames = nameType.AllowIndividualNames,
                AllowCrmNames = nameType.AllowCrmNames,
                AllowStaffNames = nameType.AllowStaffNames,
                AllowOrganisationNames = nameType.AllowOrganisationNames,
                AllowSuppliers = nameType.AllowSuppliers,
                IsAttentionDisplayed = nameType.IsAttentionDisplayed,
                IsAssignDateDisplayed = nameType.IsAssignDateDisplayed,
                IsAddressDisplayed = nameType.IsAddressDisplayed,
                IsCorrespondenceDisplayed = nameType.IsCorrespondenceDisplayed,
                IsNationalityDisplayed = nameType.NationalityFlag,
                IsClassified = nameType.IsClassified,
                IsNameStreetSaved = nameType.IsNameStreetSaved,
                IsEnforceNameRestriction = nameType.IsEnforceNameRestriction,
                IsStandardNameDisplayed = nameType.IsStandardNameDisplayed,
                IsBillPercentDisplayed = nameType.IsBillPercentDisplayed,
                IsDateCeasedDisplayed = nameType.IsDateCeasedDisplayed,
                IsDateCommencedDisplayed = nameType.IsDateCommencedDisplayed,
                IsInheritedDisplayed = nameType.IsInheritedDisplayed,
                IsNameVariantDisplayed = nameType.IsNameVariantDisplayed,
                IsReferenceNumberDisplayed = nameType.IsReferenceNumberDisplayed,
                IsRemarksDisplayed = nameType.IsRemarksDisplayed,
                DisplayNameCode = nameType.ShowNameCode == null || nameType.ShowNameCode == 0 ? DisplayNameCode.None : (DisplayNameCode)nameType.ShowNameCode,
                UseNameType = nameType.UseNameType,
                UseHomeNameRelationship = nameType.UseHomeNameRelationship,
                UpdateFromParentNameType = nameType.UpdateFromParentNameType,
                PathNameRelation = nameType.PathNameRelation != null ? new NameRelationshipModel(nameType.PathNameRelation.RelationshipCode, nameType.PathNameRelation.RelationDescription, nameType.PathNameRelation.ReverseDescription, string.Empty) : null,
                EthicalWallOption = (EthicalWallOption)nameType.EthicalWall,
                PriorityOrder = nameType.PriorityOrder
            };

            var pathNameType = _dbContext.Set<NameType>()
                .SingleOrDefault(nt => nt.NameTypeCode == nameType.PathNameType);

            if (pathNameType != null)
                saveDetails.PathNameTypePickList = new NameTypeModel(pathNameType.Id, pathNameType.Name,
                    pathNameType.NameTypeCode);

            var futureNameType = _dbContext.Set<NameType>()
                .SingleOrDefault(nt => nt.NameTypeCode == nameType.FutureNameType);

            if (futureNameType != null)
                saveDetails.FutureNameTypePickList = new NameTypeModel(futureNameType.Id, futureNameType.Name,
                    futureNameType.NameTypeCode);

            var oldNameType = _dbContext.Set<NameType>()
                .SingleOrDefault(nt => nt.NameTypeCode == nameType.OldNameType);

            if (oldNameType != null)
                saveDetails.OldNameTypePickList = new NameTypeModel(oldNameType.Id, oldNameType.Name, oldNameType.NameTypeCode);

            if (nameType.ChangeEvent != null)
                saveDetails.ChangeEvent = new Event
                {
                    Key = nameType.ChangeEvent.Id,
                    Code = nameType.ChangeEvent.Code,
                    Value = nameType.ChangeEvent.Description
                };

            if (nameType.DefaultName != null)
                saveDetails.DefaultName = new Name
                {
                    Key = nameType.DefaultName.Id,
                    Code = nameType.DefaultName.NameCode,
                    DisplayName = nameType.DefaultName.Formatted()
                };

            var nameTypeGrpMember = _dbContext.Set<NameGroupMember>()
                .Where(ntg => ntg.NameTypeCode == nameType.NameTypeCode).Select(ntg => ntg.NameGroupId).ToList();

            ICollection<NameTypeGroup> collNameTypeGrp = new List<NameTypeGroup>();
            if (nameTypeGrpMember.Any())
            {
                foreach (var item in nameTypeGrpMember)
                {
                    var nameGroup = _dbContext.Set<NameGroup>().SingleOrDefault(ng => ng.Id == item);

                    if (nameGroup != null)
                    {
                        NameTypeGroup obj = new NameTypeGroup
                        {
                            Value = nameGroup.Value,
                            Key = nameGroup.Id
                        };
                        collNameTypeGrp.Add(obj);
                    }
                }
                saveDetails.NameTypeGroup = collNameTypeGrp;
            }

            return saveDetails;
        }
    }
}
