using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Extensions;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public interface INameAccessSecurity
    {
        bool CanUpdate(Name name);
        bool CanView(Name name);
        bool CanInsert();
    }

    public class NameAccessSecurity : INameAccessSecurity
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public NameAccessSecurity(ISecurityContext securityContext, IDbContext dbContext)
        {
            if(securityContext == null) throw new ArgumentNullException("securityContext");
            if(dbContext == null) throw new ArgumentNullException("dbContext");

            _securityContext = securityContext;
            _dbContext = dbContext;
        }

        public bool CanUpdate(Name name)
        {
            return IsAccessible(name, AccessPermissionLevel.Update);
        }

        public bool CanView(Name name)
        {
            return IsAccessible(name, AccessPermissionLevel.Select);
        }

        public bool CanInsert()
        {
            var user = _securityContext.User;

            if (user.IsExternalUser) return false;

            if (!user.RowAccessPermissions.Any(r => r.Details.Any(d => d.AccessType == RowAccessType.Name)))
                return true;

            var accessPermissions = user.RowAccessPermissions.Select(p => p.Name).ToList();
            var nameAccessPermissions = _dbContext.Set<RowAccessDetail>()
                .Where(p => p.AccessType == RowAccessType.Name &&
                            (p.NameType == null || p.NameType.NameTypeCode == KnownNameTypes.UnrestrictedNameTypes) &&
                            p.PropertyType == null &&
                            p.CaseType == null && accessPermissions.Contains(p.Name)).ToList();

            var effectivePermission = nameAccessPermissions.Select(
                                                        p => new { Permission = p, Weight = PermissionWeight(p) })
                                                        .OrderByDescending(p => p.Weight)
                                                        .ThenBy(p => p.Permission.AccessLevel)
                                                        .Select(p => p.Permission).FirstOrDefault();

            if (effectivePermission == null) return false;

            const int ilevel = (int)AccessPermissionLevel.Insert;
            return (effectivePermission.AccessLevel & ilevel) == ilevel;
        }

        bool IsAccessible(Name name, AccessPermissionLevel requiredPermission)
        {
            var user = _securityContext.User;

            if (user.IsExternalUser && !ExternalUserHasAccess(name, user.Id))
                return false;

            return CheckNameAccessPermissions(name, user, requiredPermission);
        }

        bool CheckNameAccessPermissions(Name name, User user ,AccessPermissionLevel level)
        {
            if(!user.RowAccessPermissions.Any(r => r.Details.Any(d => d.AccessType == RowAccessType.Name)))
                return true;

            var nameOfficeAttributes = _dbContext.Set<TableAttributes>()
                                        .For(name)
                                        .FilterBy(TableTypes.Office)
                                        .Select(at => at.TableCodeId);

            var offices = _dbContext.Set<Office>().Where(o => nameOfficeAttributes.Contains(o.Id));

            var nameTypes = _dbContext.Set<NameTypeClassification>()
                                    .Where(ntc => ntc.IsAllowed.Value == 1 && ntc.NameId == name.Id)
                                    .Select(ntc => ntc.NameType);

            var accessPermissions = user.RowAccessPermissions.Select(p => p.Name).ToList();
            var nameAccessPermissions = _dbContext.Set<RowAccessDetail>()
                .Where(p => p.AccessType == RowAccessType.Name &&
                            (offices.Contains(p.Office) || p.Office == null) &&
                            (nameTypes.Contains(p.NameType) || p.NameType == null) &&
                            p.PropertyType == null &&
                            p.CaseType == null && accessPermissions.Contains(p.Name)).ToList();

            var effectivePermission = nameAccessPermissions.Select(
                                                        p => new {Permission = p, Weight = PermissionWeight(p)})
                                                        .OrderByDescending(p => p.Weight)
                                                        .ThenBy(p => p.Permission.AccessLevel)
                                                        .Select(p => p.Permission).FirstOrDefault();

            if(effectivePermission == null)
                return false;

            if (level == AccessPermissionLevel.Select && effectivePermission.AccessLevel >= 1) 
                return true;

            var ilevel = (int)level;
            return (effectivePermission.AccessLevel & ilevel) == ilevel;
        }

        bool ExternalUserHasAccess(Name name, int userIdentityId)
        {
            var command = _dbContext.CreateSqlCommand(string.Format(@"
                            SELECT 	N.NAMENO
                            FROM  dbo.fn_FilterUserViewNames(@userId) N"));

            command.Parameters.AddWithValue("userId", userIdentityId);

            var result = new List<int>();
            using (var reader = command.ExecuteReader())
            {
                while (reader.Read())
                {
                    var nameKey = (int)reader[0];
                    result.Add(nameKey);
                }
            }
            return result.Contains(name.Id);
        }

        static int PermissionWeight(RowAccessDetail permission)
        {
            var weight = 0;
            if(permission.Office != null)
                weight = 100;

            if(permission.NameType != null)
                weight += 10;

            return weight;
        }
    }
}
