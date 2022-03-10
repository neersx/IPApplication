using System;
using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Configuration.Screens
{
    public class ScreensModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if(modelBuilder == null) throw new ArgumentNullException("modelBuilder");

            var windowControl = modelBuilder.Entity<WindowControl>();
            windowControl.Map(m => m.ToTable("WINDOWCONTROL"));

            var topicControl = modelBuilder.Entity<TopicControl>();
            topicControl.Map(m => m.ToTable("TOPICCONTROL"));

            topicControl.HasMany(tc => tc.Filters)
                        .WithOptional()
                        .Map(c => c.MapKey("TOPICCONTROLNO"))
                        .WillCascadeOnDelete(true);

            modelBuilder.Entity<TabControl>();

            modelBuilder.Entity<ElementControl>().Map(c => c.ToTable("ELEMENTCONTROL"));

            modelBuilder.Entity<Screen>();

            modelBuilder.Entity<TopicUsage>();
        }
    }
}