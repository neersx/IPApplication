import { AfterViewInit, ChangeDetectionStrategy, Component, ContentChild, Input, OnInit } from '@angular/core';
import * as angular from 'angular';
import { IpxTopicsComponent } from 'shared/component/topics/ipx-topics.component';
import * as _ from 'underscore';
import { Step, TopicData } from './ipx-step.model';
import { StepsPersistenceService } from './steps.persistence.service';

@Component({
    selector: 'ipx-multistepsearch',
    templateUrl: './ipx-multistepsearch.component.html',
    changeDetection: ChangeDetectionStrategy.OnPush
})

export class IpxMultiStepSearchComponent implements OnInit, AfterViewInit {
    steps: Array<Step>;
    @Input() isMultiStepMode: boolean;
    @ContentChild(IpxTopicsComponent) topicsRef;

    operators: Array<string>;
    allowNavigation: boolean;

    constructor(private readonly stepsService: StepsPersistenceService) { }

    ngOnInit(): void {
        this.operators = ['AND', 'OR', 'NOT' ];
        this.steps = this.stepsService.steps;
        if (!this.steps) {
            this.steps = [];
            const firstStep = {
                id: this.steps.length + 1,
                isDefault: true,
                operator: '',
                selected: true,
                isAdvancedSearch: true
            };
            this.steps.push(firstStep);
        }
    }

    ngAfterViewInit(): void {
        if (this.steps.length > 1) {
            this.stepsService.setFilterCriteriaForAllTopics(this.topicsRef.options.topics,
                this.steps);
        }
    }

    navigate = (value): void => {
        if (value) {
            let nextStep = -1;
            this.steps.some((step, i) => {
                return step.selected ? (nextStep = i + value) : false;
            });

            if (nextStep > -1 && nextStep < this.steps.length) {
                this.goTo(this.steps[nextStep], false);
            }
        }
    };

    addStep = (): void => {
        this.stepsService.applyStepData(
            this.topicsRef.options.topics,
            this.steps
        );

        this.unselectAll();

        const newStep: Step = {
            id: Math.max.apply(Math, this.steps.map((step) => {
                return step.id;
            })) + 1,
            operator: _.first(_.filter(this.operators, (operator: string) => {
                return operator === 'OR';
            })),
            selected: true
        };

        this.steps.push(newStep);
        this.checkNavigation();
        this.goTo(newStep, true);
    };

    removeStep = (step: Step): void => {
        const index = this.steps.indexOf(step);
        if (index > -1) {
            this.steps.splice(index, 1);
        }

        this.checkNavigation();
        const nextStep = index > 0 ? index - 1 : 0;
        this.goTo(this.steps[nextStep], true);
    };

    onOperatorChange = (index: number): void => {
        const operator = this.steps[index].operator;
    };

    goTo = (step: Step, preventApply: boolean) => {
        if (!preventApply) {
            this.saveCurrentStepData();
        }

        this.setTopicFormData(step);

        this.unselectAll();

        step.selected = true;
        this.scroll();
    };

    saveCurrentStepData = (): void  => {
        _.each(this.topicsRef.options.topics, (t: any) => {
            if (_.isFunction(t.updateFormData)) {
              t.updateFormData();
            }
        });

        this.stepsService.applyStepData(
            this.topicsRef.options.topics,
            this.steps
        );
    };

    setTopicFormData = (step: Step) => {
        const topicsData = this.stepsService.getStepTopicData(this.steps, step.id);
        _.each(this.topicsRef.options.topics, (topic: any) => {
            if (topicsData && _.any(topicsData)) {
                const relevantTopicData = _.first(_.filter(topicsData, (topicData: TopicData) => {
                    return topicData.topicKey === topic.key;
                }));
                topic.loadFormData(relevantTopicData.formData);
            } else {
                const defaultFormData = this.stepsService.getTopicsDefaultViewModel(topic.key);
                topic.loadFormData(defaultFormData);
            }
        });
    };

    getFilterCriteriaForSearch = (): Array<any> => {
        const filterData: any = [];
        this.saveCurrentStepData();
        if (!this.isMultiStepMode) {
            const data = {};
            _.each(this.topicsRef.options.topics, (t: any) => {
                if (_.isFunction(t.getFilterCriteria)) {
                _.extend(data, t.getFilterCriteria());
                }
            });
            filterData.push(data);
        } else {
            _.each(this.steps, (step: any) => {
                const filterCriteria = this.getStepTopicsFilterCriteria(step);
                filterData.push(filterCriteria);
            });
        }
        this.stepsService.steps = this.steps;

        return filterData;
    };

    getStepTopicsFilterCriteria = (stepData: any) => {
        const filterCriteria: any = {};
        _.each(stepData.topicsData, (data: any) => {
          _.extend(filterCriteria, data.filterData);
          _.extend(filterCriteria, {
            id: stepData.id,
            operator: stepData.operator
          });
        });

        return filterCriteria;
    };

    scroll = (): void => {
        if (this.allowNavigation) {
            let nextStep = -1;
            this.steps.some((step: Step, i: number) => {
                if (step.selected) {
                    nextStep = i;

                    return true;
                }

                return false;
            });

            setTimeout(() => {
                const current = angular.element(
                    document.getElementById('step_' + nextStep)
                );
                if (current) {
                    const el = document.querySelector('ipx-multistepsearch div[name="wizard-header"]');
                    el.scrollLeft = nextStep * 190;
                }
            }, 100);
        }
    };

    checkNavigation(): void {
        const width = angular.element(document.getElementById('wizard'))[0]
            .clientWidth;
        this.allowNavigation =
            this.steps.length > 0
                ? this.steps.length * 220 > width || this.steps.length > 4
                : false;
    }

    unselectAll(): void {
        angular.forEach(this.steps, (step: Step) => {
            step.selected = false;
        });
    }

    trackByFn = (index: number, step: Step): any => {
        return step;
    };
}