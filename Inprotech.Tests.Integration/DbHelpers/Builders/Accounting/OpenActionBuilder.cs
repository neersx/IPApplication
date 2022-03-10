using System;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Tests.Integration.DbHelpers.Builders.Accounting
{
    class OpenActionBuilder : DbSetup
    {
        Criteria _criteria;

        public OpenActionBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public OpenAction CreateInDb(Case @case = null, DateTime? updatedDate = null)
        {
            var action = InsertWithNewId(new Action
            {
                Name = Fixture.Prefix("action"),
                ActionType = (int) ActionType.Other,
                NumberOfCyclesAllowed = 1,
                ImportanceLevel = "9"
            });
            
            @case ??= new CaseBuilder(DbContext).Create();
            
            Insert(new ValidAction
            {
                CaseTypeId = @case.TypeId,
                PropertyTypeId = @case.PropertyTypeId,
                CountryId = @case.CountryId,
                ActionId = action.Code,
                ActionName = action.Name + "(v)"
            });

            return Insert(new OpenAction(action, @case, 0, null, _criteria, true)
            {
                DateUpdated = updatedDate
            });
        }

        public OpenActionBuilder WithCriteria(Criteria criteria)
        {
            _criteria = criteria;
            return this;
        }
    }
}
