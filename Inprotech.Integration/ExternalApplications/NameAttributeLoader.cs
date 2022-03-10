using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.ExternalApplications.Crm;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Extensions;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.ExternalApplications
{
    public interface INameAttributeLoader
    {
        List<SelectionTypes> ListAttributeTypes(Name name);

        List<SelectedAttribute> ListNameAttributeData(Name name);

        List<SelectionTypes> ListAttributeTypesModifiableByExternalSystem(Name name);
    }

    public class NameAttributeLoader : INameAttributeLoader
    {
        const string Office = "OFFICE";
            
        readonly IDbContext _dbContext;

        public NameAttributeLoader(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            _dbContext = dbContext;
        }

        public List<SelectionTypes> ListAttributeTypes(Name name)
        {
            var isLead =
                name.NameTypeClassifications.Any(
                    ntc => ntc.IsAllowed == 1 && ntc.NameType.NameTypeCode.Equals(KnownNameTypes.Lead));

            if (isLead)
            {
                var leadSelectionTypes =
                    _dbContext.Set<SelectionTypes>().Where(st => st.ParentTable.Contains(KnownParentTable.Lead));

                var individualSelectionTypes =
                    _dbContext.Set<SelectionTypes>().Where(st => st.ParentTable.Contains(KnownParentTable.Individual)
                                                                 &&
                                                                 leadSelectionTypes.All(
                                                                     ld => ld.TableTypeId != st.TableTypeId));

                return leadSelectionTypes.Union(individualSelectionTypes).ToList();
            }

            var parentTable = ParentTable(name);

            return _dbContext.Set<SelectionTypes>().Where(st => st.ParentTable.Contains(parentTable)).ToList();
        }

        string ParentTable(Name name)
        {
            if (name.IsStaff)
                return KnownParentTable.Employee;

            if (name.IsIndividual)
                return KnownParentTable.Individual;

            return KnownParentTable.Organisation;
        }

        public List<SelectedAttribute> ListNameAttributeData(Name name)
        {
            var selectedAttributes = from ta in _dbContext.Set<TableAttributes>().For(name)
                join tt in _dbContext.Set<TableType>() on ta.SourceTableId equals tt.Id
                join tc in _dbContext.Set<TableCode>() on ta.TableCodeId equals tc.Id into t1
                from tcr in t1.DefaultIfEmpty()
                join o in _dbContext.Set<Office>() on ta.TableCodeId equals o.Id into t2
                from ofr in t2.DefaultIfEmpty()
                select new SelectedAttribute
                {
                    AttributeTypeId = ta.SourceTableId.GetValueOrDefault(),
                    AttributeId = ta.TableCodeId,
                    AttributeTypeDescription = tt.Name,
                    AttributeDescription = tt.DatabaseTable == Office ? ofr.Name : tcr.Name
                };

            return
                selectedAttributes.OrderBy(sa => sa.AttributeTypeDescription)
                    .ThenBy(sa => sa.AttributeDescription)
                    .ToList();
        }

        public List<SelectionTypes> ListAttributeTypesModifiableByExternalSystem(Name name)
        {
            return ListAttributeTypes(name).Where(st => st.ModifiableByService).ToList();
        }
    }
}
