using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class ActionBuilder : Builder
    {
        public ActionBuilder(IDbContext dbContext) : base(dbContext)
        {

        }

        public Action Create(string prefix = null)
        {
            if (prefix == null)
                prefix = DefaultPrefix;

            return InsertWithNewId(new Action
                                   {
                                       Name = prefix + "action"
                                   });
        }
    }
}