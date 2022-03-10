using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public interface IFunctionSecurityProvider
    {
        Task<FunctionPrivilege> BestFit(BusinessFunction businessFunction, User staff, int? ownerId = null);

        Task<IEnumerable<FunctionPrivilege>> For(BusinessFunction businessFunction, User staff, int[] ownerIds = null);
        
        Task<IEnumerable<FunctionPrivilege>> ForOthers(BusinessFunction businessFunction, User user);

        Task<bool> FunctionSecurityFor(BusinessFunction businessFunction, FunctionSecurityPrivilege required, User staff, int? ownerId = null);
        
        Task<IEnumerable<int>> FunctionSecurityFor(BusinessFunction businessFunction, FunctionSecurityPrivilege required, User staff, IEnumerable<int> ownerIds);
    }

    public class FunctionSecurityProvider : IFunctionSecurityProvider
    {
        readonly IDbContext _dbContext;

        public FunctionSecurityProvider(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<FunctionPrivilege> BestFit(BusinessFunction businessFunction, User staff, int? ownerId = null)
        {
            return new FunctionPrivilege(await FunctionAsStaff(businessFunction, staff, ToArray(ownerId)).FirstOrDefaultAsync());
        }
        
        public async Task<IEnumerable<FunctionPrivilege>> For(BusinessFunction businessFunction, User staff, int[] ownerIds = null)
        {
            return (await FunctionAsStaff(businessFunction, staff, ownerIds)
                         .ToArrayAsync())
                .Select(fs => new FunctionPrivilege(fs));
        }

        public async Task<IEnumerable<FunctionPrivilege>> ForOthers(BusinessFunction businessFunction, User user)
        {
            return (await FunctionForOtherStaff(businessFunction, user)
                .ToArrayAsync())
                .Select(fs => new FunctionPrivilege(fs));
        }

        public async Task<bool> FunctionSecurityFor(BusinessFunction businessFunction, FunctionSecurityPrivilege required, User staff, int? ownerId = null)
        {
            if (ownerId.HasValue && ownerId == staff.NameId)
            {
                return true;
            }

            var functionAccess = await FunctionAsStaff(businessFunction, staff, ToArray(ownerId)).FirstOrDefaultAsync();

            return (functionAccess?.AccessPrivileges & (short) required) == (short) required;
        }

        public async Task<IEnumerable<int>> FunctionSecurityFor(BusinessFunction businessFunction, FunctionSecurityPrivilege required, User staff, IEnumerable<int> ownerIds)
        {
            var owners = ownerIds.ToArray();
            var staffOwner = new[] {staff.NameId};
            var validOwners = owners.Except(staffOwner).ToList();
            if (!validOwners.Any())
            {
                return staffOwner;
            }

            var rules = await FunctionAsStaff(businessFunction, staff, validOwners.ToArray())
                              .Where(r => (r.AccessPrivileges & (short) required) == (short) required)
                              .ToListAsync();

            return rules.Any(x => !x.OwnerId.HasValue)
                ? owners.ToArray()
                : rules.Where(x => x.OwnerId.HasValue)
                       .Select(x => x.OwnerId.Value)
                       .Union(staffOwner)
                       .ToArray();
        }
        
        IOrderedQueryable<FunctionSecurity> FunctionForOtherStaff(BusinessFunction businessFunction, User staff)
        {
            var staffNameId = staff.NameId;
            var staffFamilyNo = staff.Name.NameFamily?.Id;

            return from fs in _dbContext.Set<FunctionSecurity>()
                   where fs.FunctionTypeId == (short) businessFunction &&
                         fs.OwnerId != staffNameId &&
                         (fs.AccessStaffId == null || fs.AccessStaffId == staffNameId) &&
                         (fs.AccessGroup == null || fs.AccessGroup == staffFamilyNo)
                   orderby fs.OwnerId.HasValue descending, fs.AccessStaffId.HasValue descending, fs.AccessGroup.HasValue descending
                   select fs;
        }

        IOrderedQueryable<FunctionSecurity> FunctionAsStaff(BusinessFunction businessFunction, User staff, int[] ownerIds)
        {
            var staffNameId = staff.NameId;
            var staffFamilyNo = staff.Name.NameFamily?.Id;

            return from fs in _dbContext.Set<FunctionSecurity>()
                   where fs.FunctionTypeId == (short) businessFunction &&
                         (fs.OwnerId == null || ownerIds.Contains((int) fs.OwnerId)) &&
                         (fs.AccessStaffId == null || fs.AccessStaffId == staffNameId) &&
                         (fs.AccessGroup == null || fs.AccessGroup == staffFamilyNo)
                   orderby fs.OwnerId.HasValue descending, fs.AccessStaffId.HasValue descending, fs.AccessGroup.HasValue descending
                   select fs;
        }

        static int[] ToArray(int? ownerId)
        {
            return (ownerId == null ? Enumerable.Empty<int>() : new[] {(int) ownerId}).ToArray();
        }
    }

    public class FunctionPrivilege
    {
        public FunctionPrivilege()
        {
            
        }

        public FunctionPrivilege(FunctionSecurity fs)
        {
            SetFunctionPrivilege(fs);
        }

        public int? OwnerId { get; internal set; }

        public short? AccessGroup { get; internal set; }

        public bool CanRead { get; internal set; }

        public bool CanInsert { get; internal set; }

        public bool CanUpdate { get; internal set; }

        public bool CanDelete { get; internal set; }

        public bool CanPost { get; internal set; }

        public bool CanFinalise { get; internal set; }

        public bool CanReverse { get; internal set; }

        public bool CanCredit { get; internal set; }

        public bool CanAdjustValue { get; internal set; }

        public bool CanConvert { get; internal set; }

        internal void SetFunctionPrivilege(FunctionSecurity fs)
        {
            if (fs == null)
                return;

            OwnerId = fs.OwnerId;
            AccessGroup = fs.AccessGroup;
            CanRead = (fs.AccessPrivileges & (short) FunctionSecurityPrivilege.CanRead) == (short) FunctionSecurityPrivilege.CanRead;
            CanInsert = (fs.AccessPrivileges & (short) FunctionSecurityPrivilege.CanInsert) == (short) FunctionSecurityPrivilege.CanInsert;
            CanUpdate = (fs.AccessPrivileges & (short) FunctionSecurityPrivilege.CanUpdate) == (short) FunctionSecurityPrivilege.CanUpdate;
            CanDelete = (fs.AccessPrivileges & (short) FunctionSecurityPrivilege.CanDelete) == (short) FunctionSecurityPrivilege.CanDelete;
            CanPost = (fs.AccessPrivileges & (short) FunctionSecurityPrivilege.CanPost) == (short) FunctionSecurityPrivilege.CanPost;
            CanAdjustValue = (fs.AccessPrivileges & (short) FunctionSecurityPrivilege.CanAdjustValue) == (short) FunctionSecurityPrivilege.CanAdjustValue;
            CanCredit = (fs.AccessPrivileges & (short) FunctionSecurityPrivilege.CanCredit) == (short) FunctionSecurityPrivilege.CanCredit;
            CanFinalise = (fs.AccessPrivileges & (short) FunctionSecurityPrivilege.CanFinalise) == (short) FunctionSecurityPrivilege.CanFinalise;
            CanReverse = (fs.AccessPrivileges & (short) FunctionSecurityPrivilege.CanReverse) == (short) FunctionSecurityPrivilege.CanReverse;
            CanConvert = (fs.AccessPrivileges & (short) FunctionSecurityPrivilege.CanConvert) == (short) FunctionSecurityPrivilege.CanConvert;
        }
    }

    public enum BusinessFunction : short
    {
        TimeRecording = 1,
        Reminder = 2,
        StaffPerformance = 3,
        BillingRevenueReports = 4,
        Billing = 5,
        Names = 6,
        EdeBatchProcessing = 7
    }
}