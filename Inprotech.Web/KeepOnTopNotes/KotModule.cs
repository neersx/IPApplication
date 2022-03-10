using Autofac;
using Inprotech.Web.KeepOnTopNotes.Kot15;
using Inprotech.Web.KeepOnTopNotes.Kot16;

namespace Inprotech.Web.KeepOnTopNotes
{
    public static class KotModule
    {
        public static void LoadKot16Module(ContainerBuilder builder)
        {
            builder.RegisterType<Kot16.KeepOnTopNotesView>().As<IKeepOnTopNotesView>();
        }

        public static void LoadKot15Module(ContainerBuilder builder)
        {
            builder.RegisterType<Kot15.KeepOnTopNotesView>().As<IKeepOnTopNotesView>();
        }
    }
}
