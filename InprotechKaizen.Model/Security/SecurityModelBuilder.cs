using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Security
{
    public class SecurityModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            ConfigureUser(modelBuilder);

            ConfigureRowAccess(modelBuilder);

            ConfigureProfiles(modelBuilder);

            ConfigureProfileProgram(modelBuilder);
            
            ConfigurePrograms(modelBuilder);
            
            modelBuilder.Entity<Role>()
                        .Map(m => m.ToTable("ROLE"));

            modelBuilder.Entity<DataTopic>();

            modelBuilder.Entity<StatusSecurity>()
                        .Map(m => m.ToTable("USERSTATUS"));

            ConfigureExternalCredentials(modelBuilder);

            ConfigureTaskSecurity(modelBuilder);

            ConfigureUserIdentityAccessLog(modelBuilder);

            modelBuilder.Entity<Permission>();

            ConfigureAccessAccount(modelBuilder);

            ConfigureBusinessFunctionSecurity(modelBuilder);

            modelBuilder.Entity<IdentityNames>();
        }
      
        static void ConfigureUser(DbModelBuilder modelBuilder)
        {
            var user = modelBuilder.Entity<User>();
            user.Map(m => m.ToTable("USERIDENTITY"));

            user.HasMany(u => u.Roles)
                .WithMany(r => r.Users)
                .Map(
                     m => m.ToTable("IDENTITYROLES")
                           .MapLeftKey("IDENTITYID")
                           .MapRightKey("ROLEID"));

            user.HasOptional(u => u.Profile)
                .WithMany()
                .Map(m => m.MapKey("PROFILEID"));

            user.HasMany(u => u.RowAccessPermissions)
                .WithMany()
                .Map(
                     m => m.ToTable("IDENTITYROWACCESS")
                           .MapLeftKey("IDENTITYID")
                           .MapRightKey("ACCESSNAME"));

            user.HasMany(u => u.Licences)
                .WithMany()
                .Map(
                     m => m.ToTable("LICENSEDUSER")
                           .MapLeftKey("USERIDENTITYID")
                           .MapRightKey("MODULEID"));

            user.HasOptional(u => u.AccessAccount)
                .WithMany()
                .Map(c => c.MapKey("ACCOUNTID"));

            var classicUser = modelBuilder.Entity<ClassicUser>();
            classicUser.HasOptional(v => v.UserIdentity)
                       .WithMany()
                       .Map(q => q.MapKey("IDENTITYID"));
        }

        static void ConfigureTaskSecurity(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Feature>();
            var webPartModule = modelBuilder.Entity<WebpartModule>();
            var securityTask = modelBuilder.Entity<SecurityTask>();
            
            securityTask.HasMany(st => st.ProvidedByFeatures)
                        .WithMany(st => st.SecurityTasks)
                        .Map(
                             m => m.ToTable("FEATURETASK")
                                   .MapLeftKey("TASKID")
                                   .MapRightKey("FEATUREID")
                );

            webPartModule.HasMany(wp => wp.ProvidedByFeatures)
                         .WithMany(wp => wp.WebpartModules)
                         .Map(
                              m => m.ToTable("FEATUREMODULE")
                                    .MapLeftKey("MODULEID")
                                    .MapRightKey("FEATUREID")
                             );
        }

        static void ConfigureRowAccess(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<RowAccess>()
                        .Map(m => m.ToTable("ROWACCESS"))
                        .HasKey(ra => new { ra.Name });

            var rowAccessDetail = modelBuilder.Entity<RowAccessDetail>()
                                              .Map(m => m.ToTable("ROWACCESSDETAIL"))
                                              .HasKey(ra => new { ra.Name, ra.SequenceNo });

            rowAccessDetail.HasOptional(rad => rad.CaseType)
                           .WithMany()
                           .Map(ct => ct.MapKey("CASETYPE"));

            rowAccessDetail.HasOptional(rad => rad.PropertyType)
                           .WithMany()
                           .Map(ct => ct.MapKey("PROPERTYTYPE"));

            rowAccessDetail.HasOptional(rad => rad.Office)
                           .WithMany()
                           .Map(ct => ct.MapKey("OFFICE"));

            rowAccessDetail.HasOptional(rad => rad.NameType)
                           .WithMany()
                           .Map(ct => ct.MapKey("NAMETYPE"));
        }
        
        static void ConfigureProfiles(DbModelBuilder modelBuilder)
        {
            var profileAttributes = modelBuilder.Entity<ProfileAttribute>();
            profileAttributes.Map(m => m.ToTable("PROFILEATTRIBUTES"));
            profileAttributes.HasKey(pa => new { pa.ProfileId, pa.InternalAttributeId });
            profileAttributes.HasRequired(pa => pa.Profile).WithMany(
                                                                     p => p.ProfileAttributes
                                                                    ).HasForeignKey(pa => pa.ProfileId);
        }

        static void ConfigurePrograms(DbModelBuilder modelBuilder)
        {
            var program = modelBuilder.Entity<Program>();
            program.Map(m => m.ToTable("PROGRAM"));
            program.HasKey(pa => pa.Id);
            program.HasOptional(p => p.ParentProgram);
        }
        static void ConfigureProfileProgram(DbModelBuilder modelBuilder)
        {
            var profileAttributes = modelBuilder.Entity<ProfileProgram>();
            profileAttributes.Map(m => m.ToTable("PROFILEPROGRAM"));
            profileAttributes.HasKey(pa => new { pa.ProfileId, pa.ProgramId });
        }

        static void ConfigureExternalCredentials(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<ExternalCredentials>()
                        .HasRequired(m => m.User)
                        .WithMany()
                        .Map(m => m.MapKey("IDENTITYID"));
        }

        static void ConfigureUserIdentityAccessLog(DbModelBuilder modelBuilder)
        {
            var log = modelBuilder.Entity<UserIdentityAccessLog>();

            log.HasRequired(u => u.User)
                .WithMany()
                .HasForeignKey(m => m.IdentityId);
        }

        static void ConfigureAccessAccount(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<AccessAccount>();
            modelBuilder.Entity<AccessAccountName>();
        }

        static void ConfigureBusinessFunctionSecurity(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<FunctionSecurity>();
        }
    }
}