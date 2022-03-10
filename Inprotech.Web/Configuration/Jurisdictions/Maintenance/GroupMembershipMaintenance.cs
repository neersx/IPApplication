using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Jurisdictions.Maintenance
{
    public interface IGroupMembershipMaintenance
    {
        void Save(Delta<GroupMembershipModel> countryGroups);

        IEnumerable<ValidationError> Validate(Delta<GroupMembershipModel> countryGroups);
    }

    public class GroupMembershipMaintenance : IGroupMembershipMaintenance
    {
        readonly IDbContext _dbContext;

        public GroupMembershipMaintenance(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public void Save(Delta<GroupMembershipModel> countryGroups)
        {
            AddGroupMemberships(countryGroups.Added);
            UpdateGroupMembership(countryGroups.Updated);
            DeleteGroupMemberships(countryGroups.Deleted);
        }
        
        void DeleteGroupMemberships(ICollection<GroupMembershipModel> deleted)
        {
            if (!deleted.Any()) return;
            var countryGroups = deleted.Select(item => _dbContext.Set<CountryGroup>().Single(_ => _.Id == item.GroupCode && _.MemberCountry == item.MemberCode));

            foreach (var item in deleted)
            {
                var designatedJurisdiction = _dbContext.Set<DueDateCalc>().WhereDesignatedJurisdiction().Where(_ => _.Jurisdiction.Id == item.MemberCode && _.Criteria.CountryId == item.GroupCode);
                _dbContext.RemoveRange(designatedJurisdiction);
            }

            _dbContext.RemoveRange(countryGroups);
        }

        void AddGroupMemberships(ICollection<GroupMembershipModel> added)
        {
            if (!added.Any()) return;

            var all = _dbContext.Set<CountryGroup>();

            foreach (var item in added)
            {
                var countryGroupSaveModel = new CountryGroup(item.GroupCode, item.MemberCode)
                {
                    FullMembershipDate = item.FullMembershipDate,
                    AssociateMemberDate = item.AssociateMemberDate,
                    DateCommenced = item.DateCommenced,
                    DateCeased = item.DateCeased,
                    AssociateMember = item.IsAssociateMember ? 1 : 0,
                    DefaultFlag = item.IsGroupDefault ? 1 : 0,
                    PreventNationalPhase = item.PreventNationalPhase,
                    PropertyTypes = string.IsNullOrEmpty(item.PropertyTypes) ? null : item.PropertyTypes
                };

                all.Add(countryGroupSaveModel);
            }
        }

        void UpdateGroupMembership(ICollection<GroupMembershipModel> updated)
        {
            if (!updated.Any()) return;

            foreach (var item in updated)
            {
                var data = _dbContext.Set<CountryGroup>().SingleOrDefault(_ => _.MemberCountry == item.MemberCode && _.Id == item.GroupCode);
                if (data != null)
                {
                    data.FullMembershipDate = item.FullMembershipDate;
                    data.AssociateMemberDate = item.AssociateMemberDate;
                    data.DateCommenced = item.DateCommenced;
                    data.DateCeased = item.DateCeased;
                    data.AssociateMember = item.IsAssociateMember ? 1 : 0;
                    data.DefaultFlag = item.IsGroupDefault ? 1 : 0;
                    data.PreventNationalPhase = item.PreventNationalPhase;
                    data.PropertyTypes = string.IsNullOrEmpty(item.PropertyTypes) ? null : item.PropertyTypes;
                }
            }
        }

        public IEnumerable<ValidationError> Validate(Delta<GroupMembershipModel> countryGroups)
        {
            var errors = new List<ValidationError>();

            foreach (var added in countryGroups.Added)
            {
                errors.AddRange(ValidateGroupMembership(added, Operation.Add));
            }

            foreach (var updated in countryGroups.Updated)
            {
                errors.AddRange(ValidateGroupMembership(updated, Operation.Update));
            }

            return errors;
        }

        IEnumerable<ValidationError> ValidateGroupMembership(GroupMembershipModel countryGroup, Operation operation)
        {
            foreach (var validationError in CommonValidations.Validate(countryGroup))
                yield return validationError;

            if (operation == Operation.Add)
            {
                if (IsDuplicate(countryGroup.GroupCode, countryGroup.MemberCode))
                {
                    yield return ValidationErrors.TopicError("groups", Resources.DuplicateGroupCodeMessage);
                }
            }

            if (countryGroup.MemberCode.IgnoreCaseEquals(countryGroup.GroupCode))
            {
                yield return ValidationErrors.TopicError("groups", Resources.SameMemberAndGroupCodeMessage);
            }

            if (countryGroup.IsAssociateMember && countryGroup.FullMembershipDate.HasValue)
            {
                yield return ValidationErrors.TopicError("groups", Resources.AssociateMemberErrorMessage);
            }

            if (countryGroup.DateCeased < countryGroup.DateCommenced)
            {
                yield return ValidationErrors.TopicError("groups", Resources.DateCeasedErrorMessage);
            }

            if (countryGroup.FullMembershipDate < countryGroup.DateCommenced)
            {
                yield return ValidationErrors.TopicError("groups", Resources.DateFullMembershipErrorMessage);
            }

            if (countryGroup.AssociateMemberDate < countryGroup.DateCommenced)
            {
                yield return ValidationErrors.TopicError("groups", Resources.DateAssociateMemberErrorMessage);
            }

            if (countryGroup.DateCeased < countryGroup.FullMembershipDate)
            {
                yield return ValidationErrors.TopicError("groups", Resources.DateLeftErrorMessage);
            }

            if (countryGroup.DateCeased < countryGroup.AssociateMemberDate)
            {
                yield return ValidationErrors.TopicError("groups", Resources.DateLeftAssoicateMemberErrorMessage);
            }
        }

        bool IsDuplicate(string group, string member)
        {
            var all = _dbContext.Set<CountryGroup>();

            return all.Any(_ => _.Id == group && _.MemberCountry == member);
        }
    }

    public class GroupMembershipModel
    {
        public string GroupCode { get; set; }
        public string MemberCode { get; set; }
        public string PropertyTypes { get; set; }
        public DateTime? DateCommenced { get; set; }
        public DateTime? DateCeased { get; set; }
        public DateTime? FullMembershipDate { get; set; }

        public DateTime? AssociateMemberDate { get; set; }
        public bool IsGroupDefault { get; set; }
        public bool PreventNationalPhase { get; set; }
        public bool IsAssociateMember { get; set; }
    }
}
