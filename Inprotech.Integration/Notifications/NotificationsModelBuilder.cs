using System;
using System.Data.Entity;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Notifications
{
    public class NotificationsModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if(modelBuilder == null) throw new ArgumentNullException("modelBuilder");
            modelBuilder.Entity<CaseNotification>();
        }
    }
}