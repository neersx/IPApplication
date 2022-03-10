using System.Linq;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    internal class FunctionSecurityBuilder : Builder
    {
        public FunctionSecurityBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public void Build(BusinessFunction function, FunctionSecurityPrivilege[] requiredPrivileges, int? staffId, int? ownerId, short? sequenceNo)
        {
            Insert(new FunctionSecurity {AccessPrivileges = (short) requiredPrivileges.Sum(_ => (int) _), FunctionTypeId = (short) function, AccessStaffId = staffId, SequenceNo = sequenceNo ?? 100, OwnerId = ownerId});
        }

        public short? BuildOrModify(BusinessFunction function, FunctionSecurityPrivilege[] requiredPrivileges, int? staffId, int? ownerId, short? sequenceNo)
        {
            var fs = DbContext.Set<FunctionSecurity>()
                              .SingleOrDefault(_ => _.FunctionTypeId == (short) function && staffId == _.AccessStaffId && ownerId == _.OwnerId && sequenceNo == _.SequenceNo);

            if (fs != null)
            {
                var existingPrivileges = fs?.AccessPrivileges;

                fs.AccessPrivileges = (short) requiredPrivileges.Sum(_ => (int) _);

                DbContext.SaveChanges();

                return existingPrivileges;
            }

            Insert(new FunctionSecurity {AccessPrivileges = (short) requiredPrivileges.Sum(_ => (int) _), FunctionTypeId = (short) function, AccessStaffId = staffId, SequenceNo = sequenceNo ?? 100, OwnerId = ownerId});

            return null;
        }
    }
}