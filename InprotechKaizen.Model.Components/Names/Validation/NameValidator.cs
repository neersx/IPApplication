using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Names.Validation
{
    public interface INameValidator
    {
        IEnumerable<DuplicateName> CheckDuplicates(
            bool isIndividual,
            bool isStaff,
            bool isClient,
            string firstName,
            string name,
            string orgOrProspectName = null,
            bool isProspectIndividual = false,
            string prospectFirstName = null);
    }

    public class NameValidator : INameValidator
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public NameValidator(ISecurityContext securityContext, IDbContext dbContext)
        {
            if (securityContext == null) throw new ArgumentNullException("securityContext");
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            _securityContext = securityContext;
            _dbContext = dbContext;
        }

        public IEnumerable<DuplicateName> CheckDuplicates(
            bool isIndividual,
            bool isStaff,
            bool isClient,
            string firstName,
            string name,
            string orgOrProspectName = null,
            bool isProspectIndividual = false,
            string prospectFirstName = null)
        {
            using (var sqlCommand = _dbContext.CreateStoredProcedureCommand("naw_ListPotentialDuplicate"))
            {
                sqlCommand.CommandTimeout = 0;
                sqlCommand.Parameters.AddRange(
                    new[]
                    {
                        new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                        new SqlParameter("@psCulture", null),
                        new SqlParameter("@pbIsIndividual", isIndividual),
                        new SqlParameter("@pbIsClient", isClient),
                        new SqlParameter("@pbIsStaff", isStaff),
                        new SqlParameter("@psFirstName", firstName),
                        new SqlParameter("@psName", name),
                        new SqlParameter("@psOrgOrProspectName", orgOrProspectName),
                        new SqlParameter("@pbIsProspectIndividual", isProspectIndividual),
                        new SqlParameter("@psProspectFirstName", prospectFirstName)
                    });

                var result = new List<DuplicateName>();
                using (var reader = sqlCommand.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        result.Add(new DuplicateName
                        {
                            Id = reader["RowKey"] as string,
                            Name = reader["Name"] as string,
                            GivenName = reader["GivenName"] as string,
                            UsedAs = reader["UsedAs"] != DBNull.Value ? (short?)reader["UsedAs"] : null,
                            Allow = Convert.ToBoolean(reader["Allow"]),
                            PostalAddress = reader["PostalAddress"] as string,
                            StreetAddress = reader["StreetAddress"] as string,
                            City = reader["City"] as string,
                            UsedAsOwner = reader["UsedAsOwner"] != DBNull.Value ? (int?) reader["UsedAsOwner"] : null,
                            UsedAsInstructor = reader["UsedAsInstructor"] != DBNull.Value ? (int?)reader["UsedAsInstructor"] : null,
                            UsedAsDebtor = reader["UsedAsDebtor"] != DBNull.Value ? (int?)reader["UsedAsDebtor"] : null,
                            MainContact = reader["MainContact"] as string,
                            Telephone = reader["Telephone"] as string,
                            WebSite = reader["WebSite"] as string,
                            Fax = reader["Fax"] as string,
                            Email = reader["Email"] as string,
                            Remarks = reader["Remarks"] as string,
                            SearchKey1 = reader["SearchKey1"] as string,
                            SearchKey2 = reader["SearchKey2"] as string
                        });
                    }

                    return result;
                }
            }
        }
    }
}