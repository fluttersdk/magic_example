<?php

namespace Tests\Feature;

use Illuminate\Notifications\Notification;

/**
 * A notification that goes through Laravel's `database` channel only, which writes the
 * row with a UUID `id` whatever key type the application's own models use.
 */
class DatabaseOnlyNotification extends Notification
{
    /**
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return [
            'database',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'title' => 'Deploy finished',
            'body' => 'Production is on the new build.',
        ];
    }
}
