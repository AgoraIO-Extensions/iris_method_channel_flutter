
#include <stdint.h>

#include "iris_event.h"

#include <memory>
#include <map>

#include "iris_life_cycle_observer.h"

using namespace irisevent;

static void Finalizer(void *isolate_callback_data, void *buffer)
{
    free(buffer);
}

class DartMessageHandlerBase
{
    EXPORT virtual void Post(EventParam *param) = 0;
};

class DartMessageHandler : public DartMessageHandlerBase
{
public:
    DartMessageHandler(Dart_Port send_port) : dart_send_port_(send_port), exit_flag_(0)
    {
        life_observer_ = new ILifeCycleObserver(
            std::bind(&DartMessageHandler::AppExitHandle, this));
        life_observer_->addApplicationObserver();
    }

    ~DartMessageHandler()
    {
        if (life_observer_)
        {
            life_observer_->removeApplicationObserver();
            delete life_observer_;
            life_observer_ = nullptr;
        }
    }

    EXPORT void Post(EventParam *param) override
    {
        if (!param)
        {
            return;
        }

        if (dart_send_port_ == 0)
        {
            return;
        }

        Dart_CObject c_event;
        c_event.type = Dart_CObject_kString;
        if (param->event == nullptr)
        {
            c_event.value.as_string = (char *)"";
        }
        else
        {
            c_event.value.as_string = const_cast<char *>(param->event);
        }

        Dart_CObject c_data;
        c_data.type = Dart_CObject_kString;
        if (param->data == nullptr)
        {
            c_data.value.as_string = (char *)"";
        }
        else
        {
            c_data.value.as_string = const_cast<char *>(param->data);
        }

        if (param->buffer_count != 0)
        {
            Dart_CObject dbuffer;
            dbuffer.type = Dart_CObject_kArray;
            dbuffer.value.as_array.length = param->buffer_count;
            Dart_CObject **type_data_array =
                new Dart_CObject *[param->buffer_count];
            for (unsigned int i = 0; i < param->buffer_count; i++)
            {
                const void *obuffer = param->buffer[i];
                unsigned int abufferLength = param->length[i];
                uint8_t *abuffer = reinterpret_cast<uint8_t *>(malloc(abufferLength));
                memcpy(abuffer, obuffer, abufferLength);

                Dart_CObject *cbuffer = new Dart_CObject;
                cbuffer->type = Dart_CObject_kExternalTypedData;
                cbuffer->value.as_external_typed_data.type = Dart_TypedData_kUint8;
                cbuffer->value.as_external_typed_data.length = abufferLength;
                cbuffer->value.as_external_typed_data.data = abuffer;
                cbuffer->value.as_external_typed_data.peer = abuffer;
                cbuffer->value.as_external_typed_data.callback = Finalizer;

                type_data_array[i] = cbuffer;
            }
            dbuffer.value.as_array.values = type_data_array;
            Dart_CObject *c_event_data_arr[] = {&c_event, &c_data, &dbuffer};

            Dart_CObject c_on_event_data;
            c_on_event_data.type = Dart_CObject_kArray;
            c_on_event_data.value.as_array.values = c_event_data_arr;
            c_on_event_data.value.as_array.length =
                sizeof(c_event_data_arr) / sizeof(c_event_data_arr[0]);

            if (exit_flag_ == 0)
                Dart_PostCObject_DL(dart_send_port_, &c_on_event_data);

            if (param->buffer_count != 0)
            {
                for (intptr_t i = 0; i < param->buffer_count; ++i)
                {
                    delete type_data_array[i];
                }
                delete[] type_data_array;
            }
        }
        else
        {
            Dart_CObject *c_event_data_arr[] = {&c_event, &c_data};

            Dart_CObject c_on_event_data;
            c_on_event_data.type = Dart_CObject_kArray;
            c_on_event_data.value.as_array.values = c_event_data_arr;
            c_on_event_data.value.as_array.length =
                sizeof(c_event_data_arr) / sizeof(c_event_data_arr[0]);

            if (exit_flag_ == 0)
                Dart_PostCObject_DL(dart_send_port_, &c_on_event_data);
        }
    }

private:
    void AppExitHandle()
    {
        exit_flag_ = 1;
    }

private:
    ILifeCycleObserver *life_observer_;
    volatile int exit_flag_;
    Dart_Port dart_send_port_;
};

class DartMessageHandlerManager : public DartMessageHandlerBase
{
public:
    ~DartMessageHandlerManager()
    {
        dartMessageHandlerMap_.clear();
    }

    intptr_t InitDartApiDL(void *data)
    {
        return Dart_InitializeApiDL(data);
    }

    void Post(EventParam *param) override
    {
        for (auto const &it : dartMessageHandlerMap_)
        {
            it.second->Post(param);
        }
    }

    void RegisterDartPort(Dart_Port send_port)
    {
        std::unique_ptr<DartMessageHandler> dartMessageHandler = std::make_unique<DartMessageHandler>(send_port);
        dartMessageHandlerMap_.emplace(send_port, std::move(dartMessageHandler));
    }

    void UnregisterDartPort(Dart_Port send_port)
    {
        dartMessageHandlerMap_.erase(send_port);
    }

private:
    std::map<Dart_Port, std::unique_ptr<DartMessageHandler>> dartMessageHandlerMap_;
};

// DartMessageHandler *dartMessageHandler_ = nullptr;
DartMessageHandlerManager *dartMessageHandlerManager_ = nullptr;

// Initialize `dart_api_dl.h`
EXPORT intptr_t InitDartApiDL(void *data)
{
    if (!dartMessageHandlerManager_)
    {
        dartMessageHandlerManager_ = new DartMessageHandlerManager();
    }

    // dartMessageHandler_ = new DartMessageHandler();
    return dartMessageHandlerManager_->InitDartApiDL(data);
}

EXPORT void Dispose()
{
    if (dartMessageHandlerManager_)
    {
        delete dartMessageHandlerManager_;
        dartMessageHandlerManager_ = nullptr;
    }
}

EXPORT void OnEvent(EventParam *param)
{
    if (dartMessageHandlerManager_)
    {
        dartMessageHandlerManager_->Post(param);
    }
}

EXPORT void RegisterDartPort(Dart_Port send_port)
{
    if (dartMessageHandlerManager_)
    {
        dartMessageHandlerManager_->RegisterDartPort(send_port);
    }
}

EXPORT void UnregisterDartPort(Dart_Port send_port)
{
    if (dartMessageHandlerManager_)
    {
        dartMessageHandlerManager_->UnregisterDartPort(send_port);
    }
}
